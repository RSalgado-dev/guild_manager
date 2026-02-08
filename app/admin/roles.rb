ActiveAdmin.register Role do
  menu priority: 3

  permit_params :name, :description, :color, :icon, :is_admin, :guild_id

  # Configura os includes para otimizar queries
  config.sort_order = "created_at_desc"

  controller do
    def scoped_collection
      super.includes(:guild)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :guild
    column :color do |role|
      content_tag(:span, role.color, style: "background-color: #{role.color}; padding: 4px 8px; border-radius: 4px; color: white;")
    end
    column "Admin" do |role|
      role.is_admin ? status_tag("Sim", class: "warning") : ""
    end
    column "Usuários" do |role|
      role.users.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :guild
  filter :guild_name, as: :string, label: "Nome da Guild"
  filter :is_admin, as: :select
  filter :created_at

  form do |f|
    f.inputs do
      f.input :guild
      f.input :name
      f.input :description, input_html: { rows: 3 }
      f.input :color, as: :string, hint: "Formato: #RRGGBB"
      f.input :icon
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
      row :color do |role|
        content_tag(:span, role.color, style: "background-color: #{role.color}; padding: 8px 16px; border-radius: 4px; color: white;")
      end
      row :icon
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

    active_admin_comments
  end
end
