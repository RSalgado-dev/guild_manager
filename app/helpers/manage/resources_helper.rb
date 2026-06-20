# frozen_string_literal: true

module Manage
  module ResourcesHelper
    def manage_record_label(record)
      return "" unless record

      if record.respond_to?(:discord_username)
        record.discord_username
      elsif record.respond_to?(:name)
        record.name
      elsif record.respond_to?(:title)
        record.title
      elsif record.respond_to?(:code)
        record.code
      else
        "##{record.id}"
      end
    end

    def manage_field_value(record, field)
      value = manage_raw_field_value(record, field)

      case field[:type]
      when :boolean
        value ? "Sim" : "Não"
      when :datetime
        value ? l(value, format: :long) : "-"
      when :json
        json_value = value.is_a?(String) ? value : JSON.pretty_generate(value || {})
        tag.pre(json_value, class: "whitespace-pre-wrap text-xs text-gray-300")
      when :multiselect
        Array(value).join(", ")
      when :select
        manage_select_field_value(value, field)
      else
        value.presence || "-"
      end
    end

    def manage_json_form_value(record, field)
      value = manage_raw_field_value(record, field)
      value.is_a?(String) ? value : JSON.pretty_generate(value || {})
    end

    def manage_collection_options(collection_key)
      case collection_key
      when :users
        @guild.users.order(:discord_username).map { |record| [ manage_record_label(record), record.id ] }
      when :roles
        roles = @guild.roles.order(:name)
        roles = roles.where.not(category: "maximum") unless current_user.maximum_role?
        roles.map { |record| [ "#{record.name} (#{record.category_label})", record.id ] }
      when :cosmetic_roles
        @guild.roles.cosmetic.order(:name).map { |record| [ record.name, record.id ] }
      when :squads
        @guild.squads.order(:name).map { |record| [ record.name, record.id ] }
      when :missions
        @guild.missions.order(:name).map { |record| [ record.name, record.id ] }
      when :achievements
        @guild.achievements.order(:name).map { |record| [ record.name, record.id ] }
      when :certificates
        @guild.certificates.order(:name).map { |record| [ record.name, record.id ] }
      when :store_items
        @guild.store_items.order(:name).map { |record| [ record.name, record.id ] }
      when :permissions
        PermissionGroup::AVAILABLE_PERMISSIONS.map { |key| [ PermissionGroup::PERMISSION_LABELS[key] || key, key ] }
      when :role_categories
        Role.categories.keys.map { |key| [ Role::CATEGORY_LABELS[key] || key, key ] }
      when :event_recurrences
        Event.recurrences.keys.map { |key| [ enum_label(key), key ] }
      when :event_statuses
        Event.statuses.keys.map { |key| [ enum_label(key), key ] }
      when :mission_types
        Mission.mission_types.keys.map { |key| [ enum_label(key), key ] }
      when :mission_frequencies
        Mission.frequencies.keys.map { |key| [ enum_label(key), key ] }
      when :mission_reward_modes
        Mission.reward_modes.keys.map { |key| [ enum_label(key), key ] }
      when :mission_submission_statuses
        MissionSubmission.statuses.keys.map { |key| [ enum_label(key), key ] }
      when :mission_request_statuses
        MissionRequest.statuses.keys.map { |key| [ enum_label(key), key ] }
      when :achievement_types
        Achievement.achievement_types.keys.map { |key| [ enum_label(key), key ] }
      when :achievement_visibilities
        Achievement.visibilities.keys.map { |key| [ enum_label(key), key ] }
      when :user_certificate_statuses
        UserCertificate.statuses.keys.map { |key| [ enum_label(key), key ] }
      when :ranking_scopes
        Ranking::RANKING_SCOPES.map { |key| [ enum_label(key), key ] }
      when :ranking_metrics
        Ranking::METRIC_LABELS.map { |key, label| [ label, key ] }
      when :ranking_sort_directions
        Ranking::SORT_DIRECTIONS.map { |key| [ enum_label(key), key ] }
      when :store_item_statuses
        StoreItem.statuses.keys.map { |key| [ enum_label(key), key ] }
      when :store_fulfillment_types
        StoreItem.fulfillment_types.keys.map { |key| [ enum_label(key), key ] }
      when :store_order_statuses
        StoreOrder.statuses.keys.map { |key| [ enum_label(key), key ] }
      when :squad_profile_statuses
        Squad.profile_change_statuses.keys.map { |key| [ enum_label(key), key ] }
      else
        []
      end
    end

    def manage_action_label(action)
      {
        "sync_access" => "Sincronizar acesso",
        "check_access" => "Verificar acesso",
        "complete_default" => "Finalizar padrão",
        "approve" => "Aprovar",
        "reject" => "Rejeitar",
        "reward" => "Recompensar",
        "revoke" => "Revogar",
        "fulfill" => "Entregar",
        "cancel" => "Cancelar",
        "approve_profile_change" => "Aprovar perfil",
        "reject_profile_change" => "Rejeitar perfil"
      }[action] || action.humanize
    end

    def manage_raw_field_value(record, field)
      if record.respond_to?(field[:name])
        record.public_send(field[:name])
      elsif field[:name].to_s.end_with?("_json")
        record.public_send(field[:name].to_s.delete_suffix("_json"))
      end
    end

    def manage_select_field_value(value, field)
      return "-" if value.blank?

      collection = Array(manage_collection_options(field[:collection])).to_h { |label, key| [ key, label ] }
      collection[value] || collection[value.to_s] || enum_label(value)
    end
  end
end
