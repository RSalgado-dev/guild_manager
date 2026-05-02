class DiscordManagedRoleReconciler
  def self.call(guild:, user: nil, client: DiscordApiClient.new)
    new(guild:, user:, client:).call
  end

  def initialize(guild:, user: nil, client: DiscordApiClient.new)
    @guild = guild
    @user = user
    @client = client
  end

  def call
    return false unless client.bot_token?
    return true if managed_roles.empty?

    users_to_reconcile.each do |guild_user|
      reconcile_user!(guild_user)
    end

    true
  rescue => e
    Rails.logger.error("Erro ao reconciliar roles gerenciadas da guild #{guild.id}: #{e.class} - #{e.message}")
    false
  end

  private

  attr_reader :guild, :user, :client

  def users_to_reconcile
    return User.where(id: user.id) if user

    guild.users
  end

  def managed_roles
    @managed_roles ||= guild.roles.where(managed_by_app: true).where.not(discord_role_id: [ nil, "" ]).to_a
  end

  def managed_role_ids
    @managed_role_ids ||= managed_roles.map(&:discord_role_id)
  end

  def managed_roles_by_discord_id
    @managed_roles_by_discord_id ||= managed_roles.index_by(&:discord_role_id)
  end

  def reconcile_user!(guild_user)
    member_data = client.guild_member(guild.discord_guild_id, guild_user.discord_id)
    unless member_data
      audit_reconciliation!(guild_user, nil, "discord_managed_role_reconcile_failed", "failed")
      return
    end

    current_role_ids = member_data["roles"] || []
    desired_role_ids = guild_user.roles
                                 .where(managed_by_app: true)
                                 .where(guild: guild)
                                 .where.not(discord_role_id: [ nil, "" ])
                                 .pluck(:discord_role_id)

    add_missing_roles!(guild_user, desired_role_ids - current_role_ids)
    remove_stale_roles!(guild_user, (current_role_ids & managed_role_ids) - desired_role_ids)

    guild_user.update_column(:discord_roles_synced_at, Time.current)
  end

  def add_missing_roles!(guild_user, discord_role_ids)
    discord_role_ids.each do |discord_role_id|
      role = managed_roles_by_discord_id[discord_role_id]
      success = client.add_guild_member_role(guild.discord_guild_id, guild_user.discord_id, discord_role_id)
      audit_reconciliation!(
        guild_user,
        role,
        "discord_managed_role_added",
        success ? "success" : "failed"
      )
    end
  end

  def remove_stale_roles!(guild_user, discord_role_ids)
    discord_role_ids.each do |discord_role_id|
      role = managed_roles_by_discord_id[discord_role_id]
      success = client.remove_guild_member_role(guild.discord_guild_id, guild_user.discord_id, discord_role_id)
      audit_reconciliation!(
        guild_user,
        role,
        "discord_managed_role_removed",
        success ? "success" : "failed"
      )
    end
  end

  def audit_reconciliation!(guild_user, role, action, result)
    AuditLog.create!(
      user: guild_user,
      guild: guild,
      action: action,
      entity_type: role ? "Role" : "User",
      entity_id: role&.id || guild_user.id,
      metadata: {
        origin: "app",
        result: result,
        discord_role_id: role&.discord_role_id,
        discord_user_id: guild_user.discord_id
      }
    )
  end
end
