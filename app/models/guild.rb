class Guild < ApplicationRecord
  has_many :users,          dependent: :destroy
  has_many :roles,          dependent: :destroy
  has_many :squads,         dependent: :destroy
  has_many :missions,       dependent: :destroy
  has_many :events,         dependent: :destroy
  has_many :achievements,   dependent: :destroy
  has_many :certificates,   dependent: :destroy

  # Ransackers para busca no ActiveAdmin
  ransacker :users_count do
    query = "(SELECT COUNT(*) FROM users WHERE users.guild_id = guilds.id)"
    Arel.sql(query)
  end

  # Permitir busca por estes atributos no ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "discord_guild_id", "discord_icon_url",
     "discord_name", "id", "name", "required_discord_role_id",
     "required_discord_role_name", "updated_at", "users_count" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "users", "roles", "squads", "missions", "events", "achievements", "certificates" ]
  end

  validates :name,
            presence: true,
            length: { maximum: 100 }

  validates :discord_guild_id,
            presence: true,
            uniqueness: true

  # Encontra ou cria guilda a partir do ID do servidor Discord
  def self.find_or_create_from_discord(discord_guild_id, discord_name = nil, discord_icon_url = nil)
    guild = find_or_initialize_by(discord_guild_id: discord_guild_id)

    if guild.new_record?
      guild.name = discord_name || "Discord Guild #{discord_guild_id}"
      guild.discord_name = discord_name
      guild.discord_icon_url = discord_icon_url
      guild.save!
    elsif discord_name.present? || discord_icon_url.present?
      # Atualiza informações se fornecidas
      updates = {}
      updates[:discord_name] = discord_name if discord_name.present?
      updates[:discord_icon_url] = discord_icon_url if discord_icon_url.present?
      guild.update(updates) if updates.any?
    end

    guild
  end
end
