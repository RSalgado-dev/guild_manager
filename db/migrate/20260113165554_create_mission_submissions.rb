class CreateMissionSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_submissions do |t|
      t.references :mission, null: false, foreign_key: true, on_delete: :cascade
      t.references :user, null: false, foreign_key: true, on_delete: :cascade
      t.string :week_reference, null: false
      t.jsonb :answers_json, null: false, default: {}
      t.datetime :rewarded_at

      t.timestamps
    end

    add_index :mission_submissions, [ :mission_id, :user_id, :week_reference ], unique: true
    add_index :mission_submissions, :week_reference
  end
end
