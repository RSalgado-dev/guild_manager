class AddCertificateRoleLink < ActiveRecord::Migration[8.1]
  def change
    add_reference :certificates, :role, foreign_key: { on_delete: :nullify }
    add_index :certificates, [ :guild_id, :role_id ]
  end
end
