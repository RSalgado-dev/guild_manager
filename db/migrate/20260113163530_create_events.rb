class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :guild, null: false, foreign_key: true, on_delete: :cascade
      t.string :title, null: false
      t.text :description
      t.string :event_type, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :status, null: false, default: "scheduled"
      t.integer :reward_currency, null: false, default: 0
      t.integer :reward_xp, null: false, default: 0
      t.bigint :creator_id, null: true

      t.timestamps
    end

    add_index :events, :starts_at
    add_index :events, :status
    add_foreign_key :events, :users, column: :creator_id, on_delete: :nullify
  end
end
