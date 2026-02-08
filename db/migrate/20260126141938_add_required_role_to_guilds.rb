class AddRequiredRoleToGuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :guilds, :required_discord_role_id, :string
    add_column :guilds, :required_discord_role_name, :string
  end
end
