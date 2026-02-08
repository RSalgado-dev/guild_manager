class Guild < ApplicationRecord
  has_many :users,          dependent: :destroy
  has_many :roles,          dependent: :destroy
  has_many :squads,         dependent: :destroy
  has_many :missions,       dependent: :destroy
  has_many :events,         dependent: :destroy
  has_many :achievements,   dependent: :destroy
  has_many :certificates,   dependent: :destroy

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
