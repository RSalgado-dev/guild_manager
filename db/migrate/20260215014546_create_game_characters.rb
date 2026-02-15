class CreateGameCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :game_characters do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :nickname, null: false
      t.integer :level, null: false
      t.integer :power, null: false

      t.timestamps
    end
  end
end
