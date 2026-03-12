ActiveAdmin.register Squad do
  menu priority: 4

  permit_params :name, :tag, :description, :guild_id, :leader_id

  # Configura os includes para otimizar queries
  config.sort_order = "created_at_desc"

  controller do
    def scoped_collection
      super.includes(:guild, :leader)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :guild
    column "Líder" do |squad|
      link_to squad.leader.discord_username, admin_user_path(squad.leader) if squad.leader
    end
    column "Membros" do |squad|
      squad.members.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :guild
  filter :guild_name, as: :string, label: "Nome da Guild"
  filter :leader, as: :select, collection: -> { User.all.map { |u| [ u.discord_username, u.id ] } }
  filter :leader_discord_username, as: :string, label: "Username do Líder"
  filter :created_at

  form do |f|
    f.inputs do
      f.input :guild
      f.input :name
      f.input :tag, hint: "TAG do squad (2-8 chars, letras e números)"
      f.input :description, input_html: { rows: 3 }
      f.input :leader, as: :select, collection: User.all.map { |u| [ u.discord_username, u.id ] }
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :guild
      row :name
      row :tag
      row :description
      row :leader do |squad|
        link_to squad.leader.discord_username, admin_user_path(squad.leader) if squad.leader
      end
      row :created_at
      row :updated_at
    end

    panel "Membros (#{squad.members.count})" do
      table_for squad.members do
        column :discord_username do |user|
          link_to user.discord_username, admin_user_path(user)
        end
        column :xp_points
        column :currency_balance
      end
    end

    active_admin_comments
  end
end
