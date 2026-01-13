class CreateUserAchievements < ActiveRecord::Migration[8.1]
  def change
    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :achievement, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :earned_at, null: false
      t.string :source_type
      t.bigint :source_id

      t.timestamps
    end

    add_index :user_achievements, [ :user_id, :achievement_id ], unique: true
    add_index :user_achievements, [ :source_type, :source_id ]
  end
end
