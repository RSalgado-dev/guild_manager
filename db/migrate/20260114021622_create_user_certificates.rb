class CreateUserCertificates < ActiveRecord::Migration[8.1]
  def change
    create_table :user_certificates do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :certificate, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :granted_by_id
      t.datetime :granted_at, null: false
      t.datetime :expires_at
      t.string :status, null: false, default: "granted"

      t.timestamps
    end

    add_index :user_certificates, [ :user_id, :certificate_id ], unique: true
    add_index :user_certificates, :status

    add_foreign_key :user_certificates, :users, column: :granted_by_id, on_delete: :nullify
  end
end
