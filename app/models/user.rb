class User < ApplicationRecord
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

  has_one :game_character, dependent: :destroy

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

  def admin?
    is_admin == true
  end

  def level
    # Calcula o nível baseado nos XP points
    # Nível 1: 0-99 XP
    # Nível 2: 100-299 XP
    # Nível 3: 300-599 XP
    # Fórmula: sqrt(xp / 100) + 1
    return 1 if xp_points.zero?

    (Math.sqrt(xp_points / 100.0).floor + 1)
  end

  def xp_for_next_level
    # XP necessário para o próximo nível
    next_level = level + 1
    ((next_level - 1) ** 2) * 100
  end

  def xp_progress_percentage
    # Percentual de progresso para o próximo nível
    current_level_xp = ((level - 1) ** 2) * 100
    next_level_xp = xp_for_next_level

    return 0 if next_level_xp == current_level_xp

    progress = ((xp_points - current_level_xp).to_f / (next_level_xp - current_level_xp) * 100).round(1)
    [ progress, 100 ].min
  end

  def primary_role
    user_roles.primary.includes(:role).first&.role || roles.first
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
        guild: user_guild
      )
      Rails.logger.info "Usuário atualizado: #{user.discord_username} (ID: #{user.id})"
    else
      # Cria novo usuário associado à guild encontrada
      user = create(
        discord_id: discord_id,
        discord_username: discord_data.name,
        discord_avatar_url: discord_data.image,
        email: discord_data.email,
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
      return
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
        return
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
        return
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

      Rails.logger.info "✅ Sincronização de roles concluída!"

    rescue => e
      Rails.logger.error "❌ Erro ao sincronizar roles: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
    end
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
