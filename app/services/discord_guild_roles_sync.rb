class DiscordGuildRolesSync
  def self.call(guild:, client: DiscordApiClient.new)
    new(guild:, client:).call
  end

  def initialize(guild:, client: DiscordApiClient.new)
    @guild = guild
    @client = client
  end

  def call
    return false unless client.bot_token?

    roles_data = client.guild_roles(guild.discord_guild_id)
    return false unless roles_data

    sync_roles!(roles_data)
    true
  rescue => e
    Rails.logger.error("Erro ao sincronizar roles da guild #{guild.id}: #{e.class} - #{e.message}")
    false
  end

  private

  attr_reader :guild, :client

  def sync_roles!(roles_data)
    roles_data.each do |discord_role|
      next if discord_role["name"] == "@everyone"

      role = Role.find_or_initialize_by(
        guild: guild,
        discord_role_id: discord_role["id"]
      )
      created = role.new_record?
      before_changes = role.slice("name", "description")

      role.assign_attributes(
        name: discord_role["name"],
        description: discord_role["name"]
      )

      next unless created || role.changed?

      role.save!
      audit_role_sync!(role, created ? "discord_role_imported" : "discord_role_updated", before_changes)
    end
  end

  def audit_role_sync!(role, action, before_changes)
    AuditLog.create!(
      guild: guild,
      action: action,
      entity_type: "Role",
      entity_id: role.id,
      metadata: {
        origin: "discord",
        result: "success",
        discord_role_id: role.discord_role_id,
        managed_by_app: role.managed_by_app,
        before: before_changes,
        after: role.slice("name", "description")
      }
    )
  end
end
