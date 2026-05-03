class DiscordApiClient
  BASE_URL = "https://discord.com"
  USER_AGENT = "DiscordBot (Workspace, 1.0)"

  attr_reader :bot_token

  def initialize(bot_token: Rails.application.credentials.dig(:discord, :bot_token))
    @bot_token = bot_token
  end

  def bot_token?
    bot_token.present?
  end

  def user_guilds(access_token)
    response = request_with_retry do
      connection.get("/api/v10/users/@me/guilds") do |request|
        request.headers["Authorization"] = "Bearer #{access_token}"
        request.headers["User-Agent"] = USER_AGENT
      end
    end

    parse_json_response(response, fallback: [])
  rescue => e
    Rails.logger.error "Erro ao buscar guilds do Discord: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    []
  end

  def guild(discord_guild_id)
    return nil unless bot_token?

    response = request_with_retry { bot_connection.get("/api/v10/guilds/#{discord_guild_id}") }
    parse_json_response(response, fallback: nil)
  rescue => e
    Rails.logger.error("Erro ao sincronizar guild #{discord_guild_id}: #{e.message}")
    nil
  end

  def guild_member(discord_guild_id, discord_user_id)
    return nil unless bot_token?

    response = request_with_retry { bot_connection.get("/api/v10/guilds/#{discord_guild_id}/members/#{discord_user_id}") }
    parse_json_response(response, fallback: nil)
  rescue => e
    Rails.logger.error("Erro ao buscar membro do Discord #{discord_user_id}: #{e.message}")
    nil
  end

  def guild_roles(discord_guild_id)
    return nil unless bot_token?

    response = request_with_retry { bot_connection.get("/api/v10/guilds/#{discord_guild_id}/roles") }
    parse_json_response(response, fallback: nil)
  rescue => e
    Rails.logger.error("Erro ao buscar roles da guild #{discord_guild_id}: #{e.message}")
    nil
  end

  def refresh_access_token(refresh_token)
    response = request_with_retry do
      connection.post("/api/oauth2/token") do |request|
        request.headers["User-Agent"] = USER_AGENT
        request.headers["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = URI.encode_www_form(
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: Rails.application.credentials.dig(:discord, :client_id),
          client_secret: Rails.application.credentials.dig(:discord, :client_secret)
        )
      end
    end

    parse_json_response(response, fallback: nil)
  rescue => e
    Rails.logger.error("Erro ao renovar access token do Discord: #{e.class} - #{e.message}")
    nil
  end

  def add_guild_member_role(discord_guild_id, discord_user_id, discord_role_id)
    write_member_role(
      :put,
      "/api/v10/guilds/#{discord_guild_id}/members/#{discord_user_id}/roles/#{discord_role_id}"
    )
  end

  def remove_guild_member_role(discord_guild_id, discord_user_id, discord_role_id)
    write_member_role(
      :delete,
      "/api/v10/guilds/#{discord_guild_id}/members/#{discord_user_id}/roles/#{discord_role_id}"
    )
  end

  private

  def connection
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.headers["Content-Type"] = "application/json"
    end
  end

  def bot_connection
    connection.tap do |conn|
      conn.headers["Authorization"] = "Bot #{bot_token}"
    end
  end

  def write_member_role(http_method, path)
    return false unless bot_token?

    response = request_with_retry { bot_connection.public_send(http_method, path) }
    return true if response.success?

    Rails.logger.warn("Discord API retornou status #{response.status} ao atualizar cargo de membro")
    false
  rescue => e
    Rails.logger.error("Erro ao atualizar cargo de membro no Discord: #{e.message}")
    false
  end

  def parse_json_response(response, fallback:)
    unless response.success?
      Rails.logger.warn("Discord API retornou status #{response.status}")
      return fallback
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.error("Discord API retornou JSON inválido: #{e.message}")
    fallback
  end

  def request_with_retry(max_attempts: 3)
    attempts = 0

    begin
      attempts += 1
      response = yield
      return response unless retryable_response?(response) && attempts < max_attempts

      sleep retry_delay_for(response, attempts)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise if attempts >= max_attempts

      Rails.logger.warn("Tentando novamente chamada Discord após #{e.class}: #{e.message}")
      sleep attempts * 0.25
      retry
    end

    response
  end

  def retryable_response?(response)
    response.status == 429 || response.status >= 500
  end

  def retry_delay_for(response, attempts)
    retry_after = response.headers["retry-after"].to_f
    return retry_after.clamp(0.1, 2.0) if retry_after.positive?

    attempts * 0.25
  end
end
