ActiveAdmin.register Role do
  menu priority: 3

  permit_params :name, :description, :discord_role_id, :is_admin, :guild_id, :category, :managed_by_app

  # Configura os includes para otimizar queries
  config.sort_order = "created_at_desc"

  controller do
    before_action :require_administrative_role_permission, only: [ :create, :update, :destroy ]

    def scoped_collection
      super.includes(:guild)
    end

    private

    def require_administrative_role_permission
      return if current_user.admin?
      return unless administrative_role_change?
      return if current_user.has_permission?(:manage_administrative_roles)

      redirect_to admin_roles_path, alert: "Você não tem permissão para gerenciar cargos administrativos."
    end

    def administrative_role_change?
      existing_role = Role.find_by(id: params[:id])
      requested_category = params.dig(:role, :category)

      existing_role&.administrative? || existing_role&.role_maximum? ||
        requested_category.in?(%w[administrative role_maximum])
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :guild
    column "Categoria" do |role|
      role.category_label
    end
    column :discord_role_id
    column "Gerenciado pelo App" do |role|
      role.managed_by_app ? status_tag("Sim", class: "ok") : status_tag("Não")
    end
    column "Admin" do |role|
      role.admin? ? status_tag("Sim", class: "warning") : ""
    end
    column "Usuários" do |role|
      role.users.count
    end
    column "Grupos de Permissão" do |role|
      role.permission_groups.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :guild
  filter :guild_name, as: :string, label: "Nome da Guild"
  filter :category, as: :select, collection: Role.categories.keys.map { |category| [ Role::CATEGORY_LABELS[category], category ] }
  filter :managed_by_app, as: :select
  filter :is_admin, as: :select
  filter :created_at

  form do |f|
    f.inputs do
      f.input :guild
      f.input :name
      f.input :description, input_html: { rows: 3 }
      f.input :category,
              as: :select,
              collection: Role.categories.keys.map { |category| [ Role::CATEGORY_LABELS[category], category ] },
              include_blank: false,
              hint: "Base libera acesso; cosmético informa status; especial libera funções; administrativo gerencia a plataforma; máximo representa acesso total."
      f.input :discord_role_id, hint: "ID do role no Discord (obtido automaticamente via sincronização)"
      f.input :managed_by_app, label: "Gerenciado pelo App?", hint: "Roles gerenciadas pelo app serão reconciliadas no Discord nas próximas etapas."
      f.input :is_admin, label: "É Admin?"
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :guild
      row :name
      row :description
      row "Categoria" do |role|
        role.category_label
      end
      row :discord_role_id
      row :managed_by_app
      row :is_admin
      row :created_at
      row :updated_at
    end

    panel "Usuários com este Cargo (#{role.users.count})" do
      table_for role.users.limit(20) do
        column :discord_username do |user|
          link_to user.discord_username, admin_user_path(user)
        end
        column :xp_points
        column :guild
      end
    end

    panel "Grupos de Permissão vinculados" do
      table_for role.permission_groups do
        column :name do |group|
          link_to group.name, admin_permission_group_path(group)
        end
        column :guild
        column "Acesso Total" do |group|
          group.all_access ? status_tag("Sim", class: "warning") : status_tag("Não")
        end
      end
    end

    active_admin_comments
  end
end
