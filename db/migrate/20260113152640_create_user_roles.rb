class CreateUserRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :role, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :primary

      t.timestamps
    end
  end
end
