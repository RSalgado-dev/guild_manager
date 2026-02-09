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

# Para testes de integração com session
class ActionDispatch::IntegrationTest
  # Helper para fazer login do usuário em testes de integração
  def sign_in(user)
    post "/fake_login_for_tests", params: { user_id: user.id }
    follow_redirect! if response.redirect?
  end
end
