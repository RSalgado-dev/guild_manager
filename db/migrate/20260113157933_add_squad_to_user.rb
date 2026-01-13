class AddSquadToUser < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :squad, null: true, foreign_key: { on_delete: :nullify }
  end
end
