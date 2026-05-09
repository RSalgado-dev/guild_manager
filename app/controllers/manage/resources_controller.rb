# frozen_string_literal: true

module Manage
  class ResourcesController < BaseController
    include ResourceRegistry

    before_action :set_config
    before_action -> { require_manage_permission!(@config[:permission]) }
    before_action :set_resource, only: [ :show, :edit, :update, :destroy, :member_action ]
    before_action :ensure_writable!, only: [ :new, :create, :edit, :update, :destroy ]

    helper_method :resource_configurations

    def index
      @resources = scoped_collection.order(created_at: :desc).limit(200)
    end

    def show
    end

    def new
      redirect_to manage_resources_path(@resource_key), alert: "❌ Este recurso não permite criação." and return if @config[:no_create]

      @resource = @model.new
      assign_default_guild
    end

    def create
      redirect_to manage_resources_path(@resource_key), alert: "❌ Este recurso não permite criação." and return if @config[:no_create]

      @resource = @model.new(resource_params)
      assign_default_guild
      assign_create_defaults
      ensure_resource_specific_permission!(@resource)

      if @resource.save
        audit_resource!("manage_resource_created")
        redirect_to manage_resource_path(@resource_key, @resource), notice: "✅ Registro criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      ensure_resource_specific_permission!(@resource)
      if @resource.update(resource_params)
        audit_resource!("manage_resource_updated")
        redirect_to manage_resource_path(@resource_key, @resource), notice: "✅ Registro atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      ensure_resource_specific_permission!(@resource)
      @resource.destroy!
      audit_resource!("manage_resource_destroyed")
      redirect_to manage_resources_path(@resource_key), notice: "✅ Registro removido."
    rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey => e
      redirect_to manage_resource_path(@resource_key, @resource), alert: "❌ #{e.message}"
    end

    def member_action
      perform_member_action!
      redirect_to manage_resource_path(@resource_key, @resource), notice: "✅ Ação executada."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to manage_resource_path(@resource_key, @resource), alert: "❌ #{e.message}"
    end

    private

    def resource_configurations
      ResourceRegistry.configs_for(current_user)
    end

    def set_config
      @resource_key = params[:resource_key].to_s
      @config = ResourceRegistry::CONFIGS[@resource_key]
      raise ActiveRecord::RecordNotFound, "Recurso não encontrado" unless @config

      @model = @config[:model]
    end

    def ensure_writable!
      return unless @config[:readonly]

      redirect_to manage_resources_path(@resource_key), alert: "❌ Este recurso é somente leitura."
    end

    def scoped_collection
      case @model.name
      when "Guild"
        Guild.where(id: @guild.id)
      when "StoreOrder"
        StoreOrder.joins(:store_item).includes(:user, :store_item).where(store_items: { guild_id: @guild.id })
      when "UserCertificate"
        UserCertificate.joins(:certificate).includes(:user, :certificate).where(certificates: { guild_id: @guild.id })
      when "UserAchievement"
        UserAchievement.joins(:achievement).includes(:user, :achievement).where(achievements: { guild_id: @guild.id })
      when "MissionSubmission"
        MissionSubmission.joins(:mission).includes(:user, :mission).where(missions: { guild_id: @guild.id })
      when "AuditLog"
        AuditLog.includes(:user).where(guild: @guild)
      when "CurrencyTransaction"
        CurrencyTransaction.joins(:user).where(users: { guild_id: @guild.id })
      else
        if @model == User || @model.column_names.include?("guild_id")
          @model.where(guild_id: @guild.id)
        else
          @model.none
        end
      end
    end

    def set_resource
      @resource = @config[:singleton] ? scoped_collection.first! : scoped_collection.find(params[:id])
    end

    def assign_default_guild
      @resource.guild = @guild if @resource.respond_to?(:guild=) && @resource.guild_id.blank?
    end

    def assign_create_defaults
      @resource.creator = current_user if @resource.is_a?(Event)
      @resource.granted_by = current_user if @resource.is_a?(UserCertificate)
    end

    def resource_params
      scalar_fields = []
      array_fields = {}

      editable_fields.each do |field|
        if field[:type] == :multiselect
          array_fields[field[:name]] = []
        else
          scalar_fields << field[:name]
        end
      end

      permitted = params.require(@model.model_name.param_key).permit(*scalar_fields, array_fields)
      array_fields.each_key do |key|
        permitted[key] = Array(permitted[key]).reject(&:blank?) if permitted.key?(key)
      end
      permitted
    end

    def editable_fields
      @config.fetch(:fields).reject { |field| field[:readonly] }
    end

    def ensure_resource_specific_permission!(resource)
      ensure_role_change_allowed!(resource) if resource.is_a?(Role)
      ensure_user_role_assignment_allowed! if resource.is_a?(User)
    end

    def ensure_role_change_allowed!(role)
      requested_category = normalized_role_category(params.dig(:role, :category))
      existing_maximum = role.persisted? && role.role_maximum?
      requested_maximum = requested_category == "role_maximum"
      existing_administrative = role.persisted? && role.administrative?
      requested_administrative = requested_category == "administrative"

      if existing_maximum || requested_maximum
        raise ActiveRecord::RecordNotFound unless current_user.maximum_role?
      elsif existing_administrative || requested_administrative
        raise ActiveRecord::RecordNotFound unless current_user.has_permission?(:manage_administrative_roles)
      end
    end

    def ensure_user_role_assignment_allowed!
      role_ids = Array(params.dig(:user, :role_ids)).reject(&:blank?)
      return if role_ids.empty?

      selected_roles = @guild.roles.where(id: role_ids)
      raise ActiveRecord::RecordNotFound if selected_roles.count != role_ids.uniq.count

      return if current_user.maximum_role?
      return if selected_roles.none?(&:role_maximum?) && selected_roles.none?(&:administrative?)

      raise ActiveRecord::RecordNotFound
    end

    def normalized_role_category(value)
      category = value.to_s.presence
      return unless category
      return category if Role.categories.key?(category)

      Role.categories.key(category)
    end

    def perform_member_action!
      action = params[:member_action].to_s
      raise ArgumentError, "Ação inválida." unless @config.fetch(:actions, []).include?(action)

      case [ @resource_key, action ]
      when [ "guild", "sync_access" ]
        sync_guild_access!
      when [ "users", "check_access" ]
        check_user_access!
      when [ "events", "complete_default" ]
        complete_event_with_default_results!
      when [ "mission_submissions", "approve" ]
        @resource.approve!(reviewer: current_user, notes: params[:notes])
      when [ "mission_submissions", "reject" ]
        @resource.reject!(reviewer: current_user, notes: params[:notes].presence || "Rejeitado pela gestão.")
      when [ "mission_submissions", "reward" ]
        @resource.reward!(reviewer: current_user)
      when [ "mission_requests", "approve" ]
        @resource.approve!(reviewer: current_user, notes: params[:notes])
      when [ "mission_requests", "reject" ]
        @resource.reject!(reviewer: current_user, notes: params[:notes].presence || "Rejeitado pela gestão.")
      when [ "user_certificates", "revoke" ]
        @resource.revoke!(revoked_by: current_user)
      when [ "store_orders", "fulfill" ]
        @resource.fulfill!(actor: current_user, notes: params[:notes])
      when [ "store_orders", "reject" ]
        @resource.reject!(actor: current_user, notes: params[:notes].presence || "Rejeitado pela gestão.")
      when [ "store_orders", "cancel" ]
        @resource.cancel!(actor: current_user)
      when [ "squads", "approve_profile_change" ]
        @resource.approve_profile_change!(reviewer: current_user)
      when [ "squads", "reject_profile_change" ]
        @resource.reject_profile_change!(reviewer: current_user, reason: params[:reason].presence || "Rejeitado pela gestão.")
      else
        raise ArgumentError, "Ação não implementada."
      end
    end

    def sync_guild_access!
      updated_count = 0
      @guild.users.find_each do |user|
        user.update_columns(has_guild_access: user.check_guild_role_access)
        updated_count += 1
      end
      AuditLog.record!(
        action: "guild_access_synced",
        actor: current_user,
        guild: @guild,
        entity: @guild,
        metadata: { "origin" => "manage", "result" => "success", "updated_count" => updated_count }
      )
    end

    def check_user_access!
      has_access = @resource.check_guild_role_access
      @resource.update_columns(has_guild_access: has_access)
      AuditLog.record!(
        action: "user_access_checked",
        actor: current_user,
        guild: @guild,
        entity: @resource,
        metadata: { "origin" => "manage", "result" => "success", "has_access" => has_access }
      )
    end

    def complete_event_with_default_results!
      raise ArgumentError, "Evento ainda não pode ser finalizado." unless @resource.review_available?

      results = @resource.event_participations.each_with_object({}) do |participation, values|
        values[participation.id] = participation.default_final_status
      end
      @resource.complete_with_results!(results: results, actor: current_user)
    end

    def audit_resource!(action)
      AuditLog.record!(
        action: action,
        actor: current_user,
        guild: @guild,
        entity: @resource,
        metadata: { "origin" => "manage", "result" => "success", "resource" => @resource_key }
      )
    end
  end
end
