class AddMissionV1Fields < ActiveRecord::Migration[8.1]
  def change
    change_table :missions, bulk: true do |t|
      t.string :mission_type, null: false, default: "manual"
      t.string :reward_mode, null: false, default: "fixed"
      t.integer :reward_currency_per_unit, null: false, default: 0
      t.integer :reward_xp_per_unit, null: false, default: 0
      t.integer :max_submissions_per_period, null: false, default: 1
      t.jsonb :metadata, null: false, default: {}
    end

    add_index :missions, [ :guild_id, :mission_type, :active ]

    change_table :mission_submissions, bulk: true do |t|
      t.string :status, null: false, default: "pending"
      t.integer :quantity, null: false, default: 1
      t.integer :period_sequence, null: false, default: 1
      t.references :reviewer, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.text :review_notes
      t.integer :reward_currency_awarded, null: false, default: 0
      t.integer :reward_xp_awarded, null: false, default: 0
    end

    remove_index :mission_submissions, column: [ :mission_id, :user_id, :week_reference ]
    add_index :mission_submissions,
              [ :mission_id, :user_id, :week_reference, :period_sequence ],
              unique: true,
              name: "idx_mission_submissions_period_sequence"
    add_index :mission_submissions, [ :status, :reviewed_at ]
  end
end
