class CreateMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :missions do |t|
      t.references :guild, null: false, foreign_key: true, on_delete: :cascade
      t.string :name, null: false
      t.text :description
      t.string :frequency, null: false, default: "weekly"
      t.integer :reward_currency, null: false, default: 0
      t.integer :reward_xp, null: false, default: 0

      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :missions, [ :guild_id, :active ]
  end
end
