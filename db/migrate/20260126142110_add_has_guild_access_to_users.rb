class AddHasGuildAccessToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :has_guild_access, :boolean, default: false, null: false
  end
end
