class AddIsPrimaryToGameCharacters < ActiveRecord::Migration[8.1]
  def up
    add_column :game_characters, :is_primary, :boolean, default: false, null: false

    execute <<~SQL
      WITH ranked AS (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at ASC, id ASC) AS row_number
        FROM game_characters
      )
      UPDATE game_characters
      SET is_primary = TRUE
      FROM ranked
      WHERE ranked.id = game_characters.id
        AND ranked.row_number = 1
    SQL

    add_index :game_characters, :user_id,
              unique: true,
              where: "is_primary = TRUE",
              name: "index_game_characters_on_user_id_primary_unique"
  end

  def down
    remove_index :game_characters, name: "index_game_characters_on_user_id_primary_unique"
    remove_column :game_characters, :is_primary
  end
end
