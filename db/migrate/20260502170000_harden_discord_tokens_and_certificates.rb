class HardenDiscordTokensAndCertificates < ActiveRecord::Migration[8.1]
  def up
    change_column :users, :discord_access_token, :text
    change_column :users, :discord_refresh_token, :text

    execute <<~SQL.squish
      INSERT INTO roles (guild_id, name, description, category, managed_by_app, is_admin, created_at, updated_at)
      SELECT DISTINCT certificates.guild_id,
             'Certificado Padrão',
             'Cargo cosmético padrão para certificados legados',
             'cosmetic',
             FALSE,
             FALSE,
             CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP
      FROM certificates
      WHERE certificates.role_id IS NULL
        AND NOT EXISTS (
          SELECT 1
          FROM roles
          WHERE roles.guild_id = certificates.guild_id
            AND roles.name = 'Certificado Padrão'
        )
    SQL

    execute <<~SQL.squish
      UPDATE certificates
      SET role_id = roles.id
      FROM roles
      WHERE certificates.role_id IS NULL
        AND roles.guild_id = certificates.guild_id
        AND roles.name = 'Certificado Padrão'
    SQL

    change_column_null :certificates, :role_id, false
  end

  def down
    change_column_null :certificates, :role_id, true
    change_column :users, :discord_access_token, :string
    change_column :users, :discord_refresh_token, :string
  end
end
