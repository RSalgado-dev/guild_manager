class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :guild, null: false, foreign_key: true

      t.string :discord_id, null: false
      t.string :discord_username
      t.string :discord_nickname
      t.string :discord_avatar_url

      t.string :discord_access_token
      t.string :discord_refresh_token
      t.datetime :discord_token_expires_at

      t.integer :xp_points, null: false, default: 0
      t.integer :currency_balance, null: false, default: 0

      t.timestamps
    end

    add_index :users, :discord_id, unique: true
  end
end
