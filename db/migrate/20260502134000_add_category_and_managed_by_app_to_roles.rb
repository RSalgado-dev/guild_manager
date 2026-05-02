class AddCategoryAndManagedByAppToRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :roles, :category, :string, null: false, default: "cosmetic"
    add_column :roles, :managed_by_app, :boolean, null: false, default: false

    add_index :roles, [ :guild_id, :category ]
    add_index :roles, :managed_by_app

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE roles
          SET category = 'administrative'
          WHERE is_admin = TRUE
        SQL

        execute <<~SQL.squish
          UPDATE roles
          SET category = 'base'
          FROM guilds
          WHERE roles.guild_id = guilds.id
            AND roles.discord_role_id IS NOT NULL
            AND roles.discord_role_id = guilds.required_discord_role_id
        SQL
      end
    end
  end
end
