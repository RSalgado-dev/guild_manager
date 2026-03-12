class AddCharacterTemplatesAndMultipleCharacters < ActiveRecord::Migration[8.1]
  def up
    add_column :guilds, :character_template, :jsonb, default: [], null: false
    add_column :game_characters, :character_data, :jsonb, default: {}, null: false

    remove_index :game_characters, :user_id
    add_index :game_characters, :user_id
  end

  def down
    remove_index :game_characters, :user_id
    add_index :game_characters, :user_id, unique: true

    remove_column :game_characters, :character_data
    remove_column :guilds, :character_template
  end
end
