class AddDiscordRolesSyncedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :discord_roles_synced_at, :datetime
    add_index :users, :discord_roles_synced_at
  end
end
