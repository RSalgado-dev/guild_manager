class AddSquadToUser < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :squad, null: true, foreign_key: true
  end
end
