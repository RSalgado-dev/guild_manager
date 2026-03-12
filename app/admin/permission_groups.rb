ActiveAdmin.register PermissionGroup do
  menu priority: 4

  permit_params :guild_id, :name, :description, :all_access, permissions: [], role_ids: []

  includes :guild, :roles
  config.sort_order = "created_at_desc"

  filter :guild
  filter :name
  filter :all_access
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :guild
    column "Acesso Total" do |group|
      group.all_access ? status_tag("Sim", class: "warning") : status_tag("Não")
    end
    column "Permissões" do |group|
      if group.all_access?
        status_tag("Todas", class: "ok")
      else
        safe_join(group.permissions.map { |permission| PermissionGroup::PERMISSION_LABELS[permission] || permission }, tag.br)
      end
    end
    column "Roles Discord" do |group|
      group.roles.count
    end
    column :created_at
    actions
  end

  form do |f|
    f.inputs "Grupo de Permissões" do
      f.input :guild
      f.input :name
      f.input :description, input_html: { rows: 3 }
      f.input :all_access, label: "Acesso Total"
      f.input :permissions,
              as: :check_boxes,
              collection: PermissionGroup::AVAILABLE_PERMISSIONS.map { |key| [ PermissionGroup::PERMISSION_LABELS[key], key ] },
              hint: "No futuro, novas permissões podem ser adicionadas sem alterar o modelo."
      f.input :roles,
              as: :check_boxes,
              collection: Role.order(:name).map { |role| [ "#{role.name} (#{role.guild.name})", role.id ] },
              hint: "Selecione uma ou mais roles do Discord que habilitam este grupo."
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :guild
      row :name
      row :description
      row :all_access
      row :permissions do |group|
        if group.all_access?
          "Todas as permissões"
        else
          group.permissions.map { |permission| PermissionGroup::PERMISSION_LABELS[permission] || permission }.join(", ")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Roles do Discord vinculadas" do
      table_for permission_group.roles do
        column :name do |role|
          link_to role.name, admin_role_path(role)
        end
        column :discord_role_id
        column :guild
      end
    end

    active_admin_comments
  end
end
