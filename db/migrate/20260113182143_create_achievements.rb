class CreateAchievements < ActiveRecord::Migration[8.1]
  def change
    create_table :achievements do |t|
      t.references :guild, null: false, foreign_key: { on_delete: :cascade }
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.string :category
      t.string :icon_url
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :achievements, [ :guild_id, :code ], unique: true
    add_index :achievements, [ :guild_id, :name ]
  end
end
