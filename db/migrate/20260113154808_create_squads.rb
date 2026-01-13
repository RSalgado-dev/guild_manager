class CreateSquads < ActiveRecord::Migration[8.1]
  def change
    create_table :squads do |t|
      t.references :guild, null: false, foreign_key: { on_delete: :cascade }
      t.integer :leader_id, null: false
      t.string :name
      t.text :description
      t.string :emblem_status, null: false, default: "none"
      t.integer :emblem_uploaded_by_id
      t.integer :emblem_reviewed_by_id
      t.datetime :emblem_reviewed_at
      t.text :emblem_rejection_reason

      t.timestamps
    end

    add_index :squads, [ :guild_id, :name ], unique: true
    add_index :squads, :emblem_status
    add_index :squads, :leader_id

    add_foreign_key :squads, :users, column: :leader_id, on_delete: :cascade
    add_foreign_key :squads, :users, column: :emblem_uploaded_by_id
    add_foreign_key :squads, :users, column: :emblem_reviewed_by_id
  end
end
