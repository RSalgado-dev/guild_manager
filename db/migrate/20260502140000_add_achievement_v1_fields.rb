class AddAchievementV1Fields < ActiveRecord::Migration[8.1]
  def change
    change_table :achievements, bulk: true do |t|
      t.string :achievement_type, null: false, default: "predefined"
      t.string :visibility, null: false, default: "catalog"
      t.jsonb :criteria, null: false, default: {}
      t.integer :reward_xp, null: false, default: 0
      t.integer :reward_currency, null: false, default: 0
      t.string :reward_profile_name_color
    end

    add_index :achievements, [ :guild_id, :achievement_type, :visibility, :active ],
              name: "idx_achievements_catalog"
    add_index :achievements, :reward_profile_name_color
  end
end
