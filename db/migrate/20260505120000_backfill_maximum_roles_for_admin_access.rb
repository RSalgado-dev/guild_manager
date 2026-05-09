class BackfillMaximumRolesForAdminAccess < ActiveRecord::Migration[8.1]
  class MigrationGuild < ActiveRecord::Base
    self.table_name = "guilds"
  end

  class MigrationRole < ActiveRecord::Base
    self.table_name = "roles"
  end

  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationUserRole < ActiveRecord::Base
    self.table_name = "user_roles"
  end

  def up
    MigrationGuild.find_each do |guild|
      maximum_role = MigrationRole.where(guild_id: guild.id, category: "maximum").first_or_create!(
        name: "Cargo Máximo",
        description: "Cargo com acesso máximo ao sistema da guilda.",
        is_admin: true,
        managed_by_app: false
      )

      MigrationUser.where(guild_id: guild.id, is_admin: true).find_each do |user|
        MigrationUserRole.find_or_create_by!(user_id: user.id, role_id: maximum_role.id) do |user_role|
          user_role.primary = false
        end
      end
    end
  end

  def down
    # Intencionalmente preserva os vínculos de cargo criados para evitar perda de acesso administrativo.
  end
end
