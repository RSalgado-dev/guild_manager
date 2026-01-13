class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.references :guild, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :is_admin, default: false, null: false
      t.string :discord_role_id

      t.timestamps
    end

    add_index :roles, [ :guild_id, :name ], unique: true
  end
end
