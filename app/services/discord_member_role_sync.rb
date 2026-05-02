class DiscordMemberRoleSync
  def self.call(user:, guild:, access_token: nil, client: DiscordApiClient.new)
    new(user:, guild:, access_token:, client:).call
  end

  def initialize(user:, guild:, access_token: nil, client: DiscordApiClient.new)
    @user = user
    @guild = guild
    @access_token = access_token
    @client = client
  end

  def call
    Rails.logger.info "🔄 Sincronizando roles para usuário #{user.discord_username}..."

    unless client.bot_token?
      Rails.logger.warn "⚠️  Bot token não configurado, não é possível sincronizar roles"
      return false
    end

    member_data = client.guild_member(guild.discord_guild_id, user.discord_id)
    return false unless member_data

    guild_roles = client.guild_roles(guild.discord_guild_id)
    return false unless guild_roles

    sync_roles!(member_data["roles"] || [], guild_roles)

    has_access = User.check_guild_role_access(guild, user.discord_id)
    user.update_columns(
      has_guild_access: has_access,
      discord_roles_synced_at: Time.current
    )

    Rails.logger.info "✅ Sincronização de roles concluída!"
    true
  rescue => e
    Rails.logger.error "❌ Erro ao sincronizar roles: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(3).join("\n")
    false
  end

  private

  attr_reader :user, :guild, :client

  def sync_roles!(member_role_ids, guild_roles)
    Rails.logger.info "📋 Usuário tem #{member_role_ids.size} roles no Discord"

    user_discord_roles = guild_roles.select { |role| member_role_ids.include?(role["id"]) }
    Rails.logger.info "🎭 Processando #{user_discord_roles.size} roles do usuário..."

    current_role_ids = user_discord_roles.filter_map do |discord_role|
      next if discord_role["name"] == "@everyone"

      db_role = Role.find_or_initialize_by(
        guild: guild,
        discord_role_id: discord_role["id"]
      )

      db_role.update!(name: discord_role["name"], description: discord_role["name"])

      user_role = user.user_roles.find_or_create_by!(role: db_role)
      audit_role_assignment!(db_role, "discord_user_role_assigned") if user_role.previously_new_record?
      db_role.id
    end

    old_roles = user.user_roles
                    .joins(:role)
                    .where.not(role_id: current_role_ids)
                    .where(roles: { managed_by_app: false })
    return if old_roles.empty?

    Rails.logger.info "🗑️  Removendo #{old_roles.size} roles antigos"
    old_roles.includes(:role).find_each do |user_role|
      audit_role_assignment!(user_role.role, "discord_user_role_removed")
    end
    old_roles.destroy_all
  end

  def audit_role_assignment!(role, action)
    AuditLog.create!(
      user: user,
      guild: guild,
      action: action,
      entity_type: "Role",
      entity_id: role.id,
      metadata: {
        origin: "discord",
        result: "success",
        discord_role_id: role.discord_role_id,
        discord_user_id: user.discord_id
      }
    )
  end
end
