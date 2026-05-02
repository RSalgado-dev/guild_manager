class CreateMissionRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_requests do |t|
      t.references :guild, null: false, foreign_key: { on_delete: :cascade }
      t.references :requester, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :reviewer, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :title, null: false
      t.text :description, null: false
      t.string :status, null: false, default: "pending"
      t.text :admin_notes
      t.datetime :reviewed_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :mission_requests, [ :guild_id, :status ]
    add_index :mission_requests, [ :requester_id, :status ]
  end
end
