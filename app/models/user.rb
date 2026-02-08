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
     "discord_username", "guild_id", "has_guild_access", "id", "is_admin",
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

    # Pega as guilds do usuário do Discord
    guilds_data = auth.extra&.raw_info&.guilds || []

    # Procura por guilds configuradas que o usuário pertence
    user_guild = nil

    guilds_data.each do |guild_data|
      user_guild = Guild.find_by(discord_guild_id: guild_data["id"])
      break if user_guild
    end

    # Se o usuário não pertence a nenhuma guild configurada, retorna nil
    return nil unless user_guild

    user = find_by(discord_id: discord_id)

    if user
      # Atualiza informações do usuário e guild se necessário
      user.update(
        discord_username: discord_data.name,
        discord_avatar_url: discord_data.image,
        guild: user_guild
      )
    else
      # Cria novo usuário associado à guild encontrada
      user = create(
        discord_id: discord_id,
        discord_username: discord_data.name,
        discord_avatar_url: discord_data.image,
        guild: user_guild,
        xp_points: 0,
        currency_balance: 0
      )
    end

    user
  end

  # Método de instância para verificar acesso
  def check_guild_role_access
    User.check_guild_role_access(guild, discord_id)
  end

  alias_method :has_guild_access?, :check_guild_role_access

  # Verifica se o usuário tem o cargo requerido pela guild
  def self.check_guild_role_access(guild, discord_user_id)
    # Se a guild não tem cargo requerido configurado, libera acesso
    return true unless guild.required_discord_role_id.present?

    # Consulta a API do Discord para obter os cargos do usuário
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
