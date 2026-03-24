class User < ApplicationRecord
  DISCORD_ROLE_SYNC_MAX_AGE = 2.minutes
  PERMISSION_CHECK_SYNC_MAX_AGE = 30.seconds
  BASE_XP_PER_LEVEL = 100
  XP_LEVEL_GROWTH_FACTOR = 1.2

  belongs_to :guild
  belongs_to :squad, optional: true

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_one :squad_led, class_name: "Squad", foreign_key: "leader_id", dependent: :destroy

  has_many :event_participations, dependent: :destroy
  has_many :events, through: :event_participations

  has_many :mission_submissions, dependent: :destroy
  has_many :missions, through: :mission_submissions

  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements

  has_many :user_certificates, dependent: :destroy
  has_many :certificates, through: :user_certificates

  has_many :currency_transactions, dependent: :destroy

  has_many :audit_logs, dependent: :nullify

  has_many :uploaded_squad_emblems,
           class_name: "Squad",
           foreign_key: :emblem_uploaded_by_id,
           dependent: :nullify

  has_many :reviewed_squad_emblems,
           class_name: "Squad",
           foreign_key: :emblem_reviewed_by_id,
           dependent: :nullify

  has_many :reviewed_squad_profile_changes,
           class_name: "Squad",
           foreign_key: :profile_change_reviewed_by_id,
           dependent: :nullify

  has_many :sent_squad_invitations,
           class_name: "SquadInvitation",
           foreign_key: :inviter_id,
           dependent: :destroy

  has_many :received_squad_invitations,
           class_name: "SquadInvitation",
           foreign_key: :invitee_id,
           dependent: :destroy

  has_many :game_characters, dependent: :destroy

  def game_character
    game_characters.order(is_primary: :desc, created_at: :asc).first
  end

  # Ransackers para busca no ActiveAdmin
  ransacker :guild_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel.sql("LOWER(guilds.name)")
  end

  ransacker :squad_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel.sql("LOWER(squads.name)")
  end

  # Permitir busca por estes atributos no ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "currency_balance", "discord_avatar_url", "discord_id",
     "discord_username", "email", "guild_id", "has_guild_access", "id", "is_admin",
     "squad_id", "updated_at", "xp_points", "guild_name", "squad_name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "squad", "roles", "user_roles", "events", "missions",
     "achievements", "certificates", "currency_transactions" ]
  end

  validates :discord_id, presence: true, uniqueness: true
  validates :xp_points, numericality: { greater_than_or_equal_to: 0 }
  validates :currency_balance, numericality: { greater_than_or_equal_to: 0 }

  scope :with_guild_access, -> { where(has_guild_access: true) }

  def admin?
    is_admin == true
  end

  def level
    current_level = 0

    while xp_points >= self.class.total_xp_for_level(current_level + 1)
      current_level += 1
    end

    current_level
  end

  def xp_for_next_level
    self.class.total_xp_for_level(level + 1)
  end

  def xp_progress_percentage
    current_level_xp = self.class.total_xp_for_level(level)
    next_level_xp = xp_for_next_level

    return 0 if next_level_xp == current_level_xp

    progress = ((xp_points - current_level_xp).to_f / (next_level_xp - current_level_xp) * 100).round(1)
    [ progress, 100 ].min
  end

  def xp_in_current_level
    xp_points - self.class.total_xp_for_level(level)
  end

  def xp_needed_in_current_level
    xp_for_next_level - self.class.total_xp_for_level(level)
  end

  def monthly_event_attendance_stats(reference_time: Time.current)
    participations = event_participations
      .joins(:event)
      .where(events: { status: Event.statuses[:completed] })
      .where(events: { starts_at: 30.days.ago(reference_time)..reference_time })
      .where.not(final_status: nil)

    total = participations.count
    counts = {
      participated: participations.participated.count,
      justified: participations.justified.count,
      absent: participations.absent.count
    }

    percentages = counts.transform_values do |count|
      total.zero? ? 0.0 : ((count.to_f / total) * 100).round(1)
    end

    {
      total: total,
      counts: counts,
      percentages: percentages
    }
  end

  def primary_role
    user_roles.primary.includes(:role).first&.role || roles.first
  end

  def permission_groups
    guild.permission_groups.joins(:roles).where(roles: { id: role_ids }).distinct
  end

  def has_permission?(permission_key)
    key = permission_key.to_s
    return true if admin?
    return false if role_ids.empty?

    guild.permission_groups
         .joins(:roles)
         .where(roles: { id: role_ids })
         .where("permission_groups.all_access = TRUE OR permission_groups.permissions ? :permission_key", permission_key: key)
         .exists?
  end

  def can_manage_members?
    has_permission?(:manage_members)
  end

  def can_manage_store?
    has_permission?(:manage_store)
  end

  def can_manage_events?
    has_permission?(:manage_events)
  end

  def can_manage_certificates?
    has_permission?(:manage_certificates)
  end

  def display_name_with_squad_tag
    return discord_username if squad.blank? || squad.tag.blank?

    "[#{squad.tag}] #{discord_username}"
  end

  def grant_achievement(achievement, source: nil)
    UserAchievement.create!(
      user: self,
      achievement:,
      source_type: source&.class&.name,
      source_id: source&.id
    )
  rescue ActiveRecord::RecordNotUnique
    # já possui, ignora silenciosamente
    user_achievements.find_by(achievement: achievement)
  end

  def apply_currency!(delta, reason: nil, description: nil, metadata: {})
    new_balance = currency_balance + delta

    transaction do
      update!(currency_balance: new_balance)

      currency_transactions.create!(
        amount:        delta,
        balance_after: new_balance,
        reason_type:   reason&.class&.name,
        reason_id:     reason&.id,
        description:   description,
        metadata:      metadata
      )
    end
  end

  def apply_xp!(delta)
    transaction do
      lock!
      update!(xp_points: xp_points + delta)
    end
  end

  def self.total_xp_for_level(target_level)
    return 0 if target_level <= 0

    (1..target_level).sum { |level_number| xp_required_for_level(level_number) }
  end

  def self.xp_required_for_level(target_level)
    return 0 if target_level <= 0

    (BASE_XP_PER_LEVEL * (XP_LEVEL_GROWTH_FACTOR**(target_level - 1))).round
  end

  # Encontra ou cria usuário a partir dos dados do Discord OAuth
  # Retorna nil se o usuário não pertencer a nenhuma guild configurada
  # Define has_guild_access baseado no cargo do Discord
  def self.find_or_create_from_discord(auth)
    discord_data = auth.info
    discord_id = auth.uid
    access_token = auth.credentials.token

    # O omniauth-discord não retorna guilds automaticamente
    # Precisamos fazer uma requisição manual para a API do Discord
    guilds_data = fetch_user_guilds(access_token)

    Rails.logger.info "Discord OAuth - Guilds do usuário: #{guilds_data.map { |g| "#{g['name']} (#{g['id']})" }.join(', ')}"

    # Procura por guilds configuradas que o usuário pertence
    user_guild = nil

    guilds_data.each do |guild_data|
      user_guild = Guild.find_by(discord_guild_id: guild_data["id"])
      if user_guild
        Rails.logger.info "Guild encontrada: #{user_guild.name}"
        break
      end
    end

    # Se o usuário não pertence a nenhuma guild configurada, retorna nil
    if user_guild.nil?
      Rails.logger.warn "Nenhuma guild configurada encontrada para o usuário"
      return nil
    end

    user = find_by(discord_id: discord_id)

    if user
      # Atualiza informações do usuário e guild se necessário
      user.update(
        discord_username: discord_data.name,
        discord_avatar_url: discord_data.image,
        email: discord_data.email,
        guild: user_guild,
        discord_access_token: auth.credentials.token,
        discord_refresh_token: auth.credentials.refresh_token,
        discord_token_expires_at: auth.credentials.expires_at ? Time.zone.at(auth.credentials.expires_at) : nil
      )
      Rails.logger.info "Usuário atualizado: #{user.discord_username} (ID: #{user.id})"
    else
      # Cria novo usuário associado à guild encontrada
      user = create(
        discord_id: discord_id,
        discord_username: discord_data.name,
        discord_avatar_url: discord_data.image,
        email: discord_data.email,
        discord_access_token: auth.credentials.token,
        discord_refresh_token: auth.credentials.refresh_token,
        discord_token_expires_at: auth.credentials.expires_at ? Time.zone.at(auth.credentials.expires_at) : nil,
        guild: user_guild,
        xp_points: 0,
        currency_balance: 0
      )
      Rails.logger.info "Novo usuário criado: #{user.discord_username} (ID: #{user.id})"
    end

    # Sincroniza os roles do usuário no Discord com o banco de dados
    user.sync_discord_roles(access_token, user_guild) if user.persisted?

    # Atualiza o campo has_guild_access baseado nos roles sincronizados
    if user.persisted?
      user.update_column(:has_guild_access, user.check_guild_role_access)
      Rails.logger.info "has_guild_access atualizado para: #{user.has_guild_access}"
    end

    user
  end

  # Busca as guilds do usuário na API do Discord
  def self.fetch_user_guilds(access_token)
    require "net/http"
    require "uri"
    require "json"

    Rails.logger.info "Buscando guilds com access_token: #{access_token[0..10]}..."

    uri = URI("https://discord.com/api/v10/users/@me/guilds")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["User-Agent"] = "DiscordBot (Workspace, 1.0)"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    Rails.logger.info "Response status: #{response.code}"
    Rails.logger.info "Response content-type: #{response['content-type']}"
    Rails.logger.info "Response body (primeiros 300 chars): #{response.body[0..300]}"

    if response.code == "200" && response["content-type"]&.include?("application/json")
      guilds = JSON.parse(response.body)
      Rails.logger.info "✓ Guilds parseadas com sucesso: #{guilds.size} encontradas"
      if guilds.size > 0
        Rails.logger.info "Primeiras 5 guilds: #{guilds.first(5).map { |g| "#{g['name']} (#{g['id']})" }.join(', ')}"
      end
      guilds
    else
      Rails.logger.error "✗ Erro ao buscar guilds: Status #{response.code}, Content-Type: #{response['content-type']}"
      Rails.logger.error "Body: #{response.body[0..500]}"

      # Se retornou HTML, provavelmente o token não tem scope de guilds
      if response["content-type"]&.include?("text/html")
        Rails.logger.error "⚠️  ATENÇÃO: Discord retornou HTML. O access token pode não ter permissão 'guilds'."
        Rails.logger.error "⚠️  Revogue a autorização no Discord e autorize novamente!"
      end
      []
    end
  rescue => e
    Rails.logger.error "Erro ao buscar guilds do Discord: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    []
  end

  # Método de instância para verificar acesso
  def check_guild_role_access
    User.check_guild_role_access(guild, discord_id)
  end

  alias_method :has_guild_access?, :check_guild_role_access

  # Sincroniza os roles do Discord do usuário com o banco de dados
  # Busca os roles do usuário no servidor, cria/atualiza no banco e vincula
  def sync_discord_roles(access_token, user_guild)
    Rails.logger.info "🔄 Sincronizando roles para usuário #{discord_username}..."

    bot_token = Rails.application.credentials.dig(:discord, :bot_token)
    unless bot_token
      Rails.logger.warn "⚠️  Bot token não configurado, não é possível sincronizar roles"
      return false
    end

    begin
      require "net/http"
      require "uri"
      require "json"

      # 1. Buscar os dados do membro no servidor (inclui roles dele)
      uri = URI("https://discord.com/api/v10/guilds/#{user_guild.discord_guild_id}/members/#{discord_id}")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bot #{bot_token}"
      request["Content-Type"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      unless response.code == "200"
        Rails.logger.error "❌ Erro ao buscar membro do Discord: #{response.code}"
        return false
      end

      member_data = JSON.parse(response.body)
      user_role_ids = member_data["roles"] || []

      Rails.logger.info "📋 Usuário tem #{user_role_ids.size} roles no Discord"

      # 2. Buscar todos os roles do servidor para obter nomes e detalhes
      uri = URI("https://discord.com/api/v10/guilds/#{user_guild.discord_guild_id}/roles")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bot #{bot_token}"
      request["Content-Type"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      unless response.code == "200"
        Rails.logger.error "❌ Erro ao buscar roles do servidor: #{response.code}"
        return false
      end

      guild_roles = JSON.parse(response.body)

      # 3. Filtrar apenas os roles que o usuário possui
      user_discord_roles = guild_roles.select { |r| user_role_ids.include?(r["id"]) }

      Rails.logger.info "🎭 Processando #{user_discord_roles.size} roles do usuário..."

      # 4. Criar/atualizar roles no banco e vincular ao usuário
      current_role_ids = []

      user_discord_roles.each do |discord_role|
        # Pular o role @everyone
        next if discord_role["name"] == "@everyone"

        # Buscar ou criar o role no banco de dados
        db_role = Role.find_or_initialize_by(
          guild: user_guild,
          discord_role_id: discord_role["id"]
        )

        # Atualizar informações do role
        db_role.update(
          name: discord_role["name"],
          description: discord_role["name"]
        )

        current_role_ids << db_role.id

        # Criar associação user_role se não existir
        unless user_roles.exists?(role_id: db_role.id)
          user_roles.create(role: db_role)
          Rails.logger.info "✅ Role vinculado: #{db_role.name}"
        end
      end

      # 5. Remover roles antigos que o usuário não tem mais
      old_roles = user_roles.where.not(role_id: current_role_ids)
      if old_roles.any?
        Rails.logger.info "🗑️  Removendo #{old_roles.size} roles antigos"
        old_roles.destroy_all
      end

      has_access = User.check_guild_role_access(user_guild, discord_id)
      update_columns(
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
  end

  def sync_discord_roles_if_stale!(max_age: DISCORD_ROLE_SYNC_MAX_AGE, force: false)
    return false unless persisted? && guild.present?
    return false if !force && discord_roles_synced_at.present? && discord_roles_synced_at >= max_age.ago

    sync_discord_roles(discord_access_token, guild)
  end

  # Verifica se o usuário tem o cargo requerido pela guild
  def self.check_guild_role_access(guild, discord_user_id)
    # Se a guild não tem cargo requerido configurado, libera acesso
    return true unless guild.required_discord_role_id.present?

    # Buscar o usuário no banco
    user = find_by(discord_id: discord_user_id)

    # Se o usuário existe no banco, verificar pelos roles sincronizados
    if user
      has_required_role = user.roles.exists?(
        guild: guild,
        discord_role_id: guild.required_discord_role_id
      )

      if has_required_role
        Rails.logger.info "✅ Usuário #{user.discord_username} tem o role requerido (banco de dados)"
        return true
      else
        Rails.logger.warn "⚠️  Usuário #{user.discord_username} NÃO tem o role requerido"
        Rails.logger.info "Roles do usuário: #{user.roles.pluck(:name, :discord_role_id)}"
        Rails.logger.info "Role requerido: #{guild.required_discord_role_id}"
        return false
      end
    end

    # Fallback: Se o usuário não existe no banco, consulta a API do Discord
    Rails.logger.info "Fallback: Consultando API do Discord para verificar role"
    bot_token = Rails.application.credentials.dig(:discord, :bot_token)
    return true unless bot_token # Se não tem bot token, libera acesso (modo permissivo)

    begin
      conn = Faraday.new(url: "https://discord.com/api/v10") do |f|
        f.headers["Authorization"] = "Bot #{bot_token}"
        f.headers["Content-Type"] = "application/json"
      end

      response = conn.get("/guilds/#{guild.discord_guild_id}/members/#{discord_user_id}")

      if response.success?
        member_data = JSON.parse(response.body)
        user_roles = member_data["roles"] || []

        # Verifica se o usuário tem o cargo requerido
        user_roles.include?(guild.required_discord_role_id)
      else
        Rails.logger.warn("Erro ao verificar cargos do usuário #{discord_user_id}: #{response.status}")
        true # Modo permissivo em caso de erro
      end
    rescue => e
      Rails.logger.error("Erro ao verificar cargos do Discord: #{e.message}")
      true # Modo permissivo em caso de erro
    end
  end
end
