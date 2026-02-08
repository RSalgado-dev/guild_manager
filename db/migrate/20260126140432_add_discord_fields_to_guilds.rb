class AddDiscordFieldsToGuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :guilds, :discord_guild_id, :string, null: false
    add_index :guilds, :discord_guild_id, unique: true
    add_column :guilds, :discord_name, :string
    add_column :guilds, :discord_icon_url, :string
  end
end
