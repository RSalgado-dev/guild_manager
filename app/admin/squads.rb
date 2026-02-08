ActiveAdmin.register Squad do
  menu priority: 4

  permit_params :name, :description, :guild_id, :leader_id, :max_members

  index do
    selectable_column
    id_column
    column :name
    column :guild
    column "Líder" do |squad|
      link_to squad.leader.discord_username, admin_user_path(squad.leader) if squad.leader
    end
    column "Membros" do |squad|
      "#{squad.members.count}/#{squad.max_members || '∞'}"
    end
    column :created_at
    actions
  end

  filter :name
  filter :guild
  filter :created_at

  form do |f|
    f.inputs do
      f.input :guild
      f.input :name
      f.input :description, input_html: { rows: 3 }
      f.input :leader, as: :select, collection: User.all.map { |u| [u.discord_username, u.id] }
      f.input :max_members, hint: "Deixe vazio para ilimitado"
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :guild
      row :name
      row :description
      row :leader do |squad|
        link_to squad.leader.discord_username, admin_user_path(squad.leader) if squad.leader
      end
      row :max_members
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
