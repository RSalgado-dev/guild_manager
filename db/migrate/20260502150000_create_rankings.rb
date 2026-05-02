class CreateRankings < ActiveRecord::Migration[8.1]
  def change
    create_table :rankings do |t|
      t.references :guild, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :description
      t.string :ranking_scope, null: false, default: "users"
      t.string :metric, null: false
      t.string :sort_direction, null: false, default: "desc"
      t.integer :entries_limit, null: false, default: 10
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :rankings, [ :guild_id, :active, :position ]
    add_index :rankings, [ :guild_id, :name ], unique: true
  end
end
