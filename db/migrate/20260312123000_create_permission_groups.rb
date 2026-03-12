class CreatePermissionGroups < ActiveRecord::Migration[8.1]
  def up
    create_table :permission_groups do |t|
      t.references :guild, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :permissions, null: false, default: []
      t.boolean :all_access, null: false, default: false

      t.timestamps
    end

    add_index :permission_groups, [ :guild_id, :name ], unique: true

    create_table :permission_group_roles do |t|
      t.references :permission_group, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end

    add_index :permission_group_roles, [ :permission_group_id, :role_id ], unique: true, name: "idx_permission_group_roles_unique"

    Guild.find_each do |guild|
      PermissionGroup.create!(
        guild: guild,
        name: "Administração",
        description: "Grupo padrão com acesso total ao sistema.",
        all_access: true,
        permissions: PermissionGroup::AVAILABLE_PERMISSIONS
      )
    end
  end

  def down
    drop_table :permission_group_roles
    drop_table :permission_groups
  end
end
