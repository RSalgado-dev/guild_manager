ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "ostruct"
require "mocha/minitest"

# Configura WebMock para permitir requisições locais
WebMock.disable_net_connect!(allow_localhost: true)

# Configura OmniAuth para modo de teste
OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper para stub da API Discord fetch_user_guilds
    def stub_discord_user_guilds(access_token: "fake_access_token", guilds: [])
      stub_request(:get, "https://discord.com/api/v10/users/@me/guilds")
        .with(headers: {
          "Authorization" => "Bearer #{access_token}",
          "User-Agent" => "DiscordBot (Workspace, 1.0)"
        })
        .to_return(status: 200, body: guilds.to_json, headers: { "Content-Type" => "application/json" })
    end

    # Helper para stub da API Discord sync_discord_roles (busca de membro)
    def stub_discord_guild_member(guild_id:, user_id:, roles: [])
      stub_request(:get, "https://discord.com/api/v10/guilds/#{guild_id}/members/#{user_id}")
        .to_return(status: 200, body: { user: { id: user_id }, roles: roles }.to_json, headers: { "Content-Type" => "application/json" })
    end

    # Helper para stub da API Discord fetch de roles da guild
    def stub_discord_guild_roles(guild_id:, roles: [])
      stub_request(:get, "https://discord.com/api/v10/guilds/#{guild_id}/roles")
        .to_return(status: 200, body: roles.to_json, headers: { "Content-Type" => "application/json" })
    end

    # Limpa mocks do OmniAuth após cada teste
    teardown do
      OmniAuth.config.mock_auth[:discord] = nil
    end
  end
end

# Helper para testes de integração
class ActionDispatch::IntegrationTest
  # Simula login do usuário definindo a sessão diretamente
  def sign_in(user)
    # Configurar bot token fake para testes
    Rails.application.credentials.stubs(:dig).with(:discord, :bot_token).returns("fake_bot_token")

    # Stub da API Discord - User Guilds
    stub_discord_user_guilds(
      access_token: user.discord_access_token || "fake_token",
      guilds: [ { "id" => user.guild.discord_guild_id, "name" => user.guild.name } ]
    )

    # Stub da API Discord - Guild Member (para sync_discord_roles)
    # Inclui o role requerido pela guild para que o usuário tenha acesso
    stub_discord_guild_member(
      guild_id: user.guild.discord_guild_id,
      user_id: user.discord_id,
      roles: [ user.guild.required_discord_role_id ] # Inclui o role requerido
    )

    # Stub da API Discord - Guild Roles (para sync_discord_roles)
    stub_discord_guild_roles(
      guild_id: user.guild.discord_guild_id,
      roles: [
        {
          "id" => user.guild.required_discord_role_id,
          "name" => user.guild.required_discord_role_name || "Membro"
        }
      ]
    )

    # Simula o callback do OAuth que cria a sessão
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({
      provider: "discord",
      uid: user.discord_id,
      info: {
        name: user.discord_username,
        email: user.email || "test@example.com",
        image: user.discord_avatar_url
      },
      credentials: {
        token: user.discord_access_token || "fake_token",
        refresh_token: user.discord_refresh_token || "fake_refresh_token",
        expires_at: (Time.now + 1.week).to_i
      }
    })

    get "/auth/discord/callback"
    follow_redirect! if response.redirect?
  end

  # Simula login de usuário SEM o role requerido (para testar acesso restrito)
  def sign_in_without_role(user)
    Rails.application.credentials.stubs(:dig).with(:discord, :bot_token).returns("fake_bot_token")

    stub_discord_user_guilds(
      access_token: user.discord_access_token || "fake_token",
      guilds: [ { "id" => user.guild.discord_guild_id, "name" => user.guild.name } ]
    )

    # SEM o role requerido
    stub_discord_guild_member(
      guild_id: user.guild.discord_guild_id,
      user_id: user.discord_id,
      roles: [] # Roles vazios
    )

    stub_discord_guild_roles(
      guild_id: user.guild.discord_guild_id,
      roles: []
    )

    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({
      provider: "discord",
      uid: user.discord_id,
      info: {
        name: user.discord_username,
        email: user.email || "test@example.com",
        image: user.discord_avatar_url
      },
      credentials: {
        token: user.discord_access_token || "fake_token",
        refresh_token: user.discord_refresh_token || "fake_refresh_token",
        expires_at: (Time.now + 1.week).to_i
      }
    })

    get "/auth/discord/callback"
    follow_redirect! if response.redirect?
  end

  # Helper para stub da API Discord fetch_user_guilds
  def stub_discord_user_guilds(access_token: "fake_access_token", guilds: [])
    stub_request(:get, "https://discord.com/api/v10/users/@me/guilds")
      .with(headers: {
        "Authorization" => "Bearer #{access_token}",
        "User-Agent" => "DiscordBot (Workspace, 1.0)"
      })
      .to_return(status: 200, body: guilds.to_json, headers: { "Content-Type" => "application/json" })
  end

  # Helper para stub da API Discord Guild Member
  def stub_discord_guild_member(guild_id:, user_id:, roles: [])
    stub_request(:get, "https://discord.com/api/v10/guilds/#{guild_id}/members/#{user_id}")
      .with(headers: {
        "Authorization" => "Bot fake_bot_token",
        "Content-Type" => "application/json"
      })
      .to_return(status: 200, body: { user: { id: user_id }, roles: roles }.to_json, headers: { "Content-Type" => "application/json" })
  end

  # Helper para stub da API Discord Guild Roles
  def stub_discord_guild_roles(guild_id:, roles: [])
    stub_request(:get, "https://discord.com/api/v10/guilds/#{guild_id}/roles")
      .with(headers: {
        "Authorization" => "Bot fake_bot_token",
        "Content-Type" => "application/json"
      })
      .to_return(status: 200, body: roles.to_json, headers: { "Content-Type" => "application/json" })
  end
end
