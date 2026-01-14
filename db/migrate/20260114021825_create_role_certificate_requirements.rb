class CreateRoleCertificateRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :role_certificate_requirements do |t|
      t.references :role, null: false, foreign_key: { on_delete: :cascade }
      t.references :certificate, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :required, null: false, default: true

      t.timestamps
    end

    add_index :role_certificate_requirements, [ :role_id, :certificate_id ], unique: true
  end
end
