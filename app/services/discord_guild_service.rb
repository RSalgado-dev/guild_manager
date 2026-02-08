# Serviço para sincronizar guilds do Discord com a aplicação
#
# Uso:
#   DiscordGuildService.sync_guild(discord_guild_id)
#   DiscordGuildService.sync_all_guilds
#
class DiscordGuildService
  # Sincroniza uma guild específica do Discord
  def self.sync_guild(discord_guild_id, bot_token = nil)
    bot_token ||= Rails.application.credentials.dig(:discord, :bot_token)

    return unless bot_token

    # Faz requisição à API do Discord para obter informações da guild
    conn = Faraday.new(url: "https://discord.com/api/v10") do |f|
      f.headers["Authorization"] = "Bot #{bot_token}"
      f.headers["Content-Type"] = "application/json"
    end

    response = conn.get("/guilds/#{discord_guild_id}")

    if response.success?
      guild_data = JSON.parse(response.body)

      Guild.find_or_create_from_discord(
        guild_data["id"],
        guild_data["name"],
        guild_icon_url(guild_data)
      )
    else
      Rails.logger.error("Erro ao sincronizar guild #{discord_guild_id}: #{response.status}")
      nil
    end
  rescue => e
    Rails.logger.error("Erro ao sincronizar guild #{discord_guild_id}: #{e.message}")
    nil
  end

  # Retorna URL do ícone da guild
  def self.guild_icon_url(guild_data)
    return nil unless guild_data["icon"]

    "https://cdn.discordapp.com/icons/#{guild_data['id']}/#{guild_data['icon']}.png"
  end

  # Sincroniza todas as guilds dos usuários existentes
  def self.sync_user_guilds(bot_token = nil)
    bot_token ||= Rails.application.credentials.dig(:discord, :bot_token)
    return unless bot_token

    # Pega todos os discord_guild_ids únicos dos usuários
    guild_ids = User.joins(:guild).distinct.pluck("guilds.discord_guild_id")

    guild_ids.each do |guild_id|
      next if guild_id == "default_guild"
      sync_guild(guild_id, bot_token)
    end
  end
end
