class RestrictCertificateRoleDeletion < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :certificates, :roles
    add_foreign_key :certificates, :roles
  end
end
