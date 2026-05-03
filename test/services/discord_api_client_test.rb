require "test_helper"

class DiscordApiClientTest < ActiveSupport::TestCase
  test "#user_guilds retorna guilds do usuário autenticado" do
    stub_discord_user_guilds(
      access_token: "access_token",
      guilds: [ { "id" => "123", "name" => "Guild Teste" } ]
    )

    guilds = DiscordApiClient.new.user_guilds("access_token")

    assert_equal 1, guilds.size
    assert_equal "123", guilds.first["id"]
  end

  test "#user_guilds retorna array vazio em erro da API" do
    stub_request(:get, "https://discord.com/api/v10/users/@me/guilds")
      .to_return(status: 500, body: "erro")

    assert_equal [], DiscordApiClient.new.user_guilds("access_token")
  end

  test "#guild_member retorna nil sem bot token" do
    client = DiscordApiClient.new(bot_token: nil)

    assert_nil client.guild_member("guild_id", "user_id")
  end

  test "#guild_member retorna dados do membro com bot token" do
    stub_discord_guild_member(
      guild_id: "guild_id",
      user_id: "user_id",
      roles: [ "role_id" ]
    )

    member = DiscordApiClient.new(bot_token: "fake_bot_token").guild_member("guild_id", "user_id")

    assert_equal [ "role_id" ], member["roles"]
  end

  test "#add_guild_member_role adiciona cargo com bot token" do
    stub_request(:put, "https://discord.com/api/v10/guilds/guild_id/members/user_id/roles/role_id")
      .with(headers: { "Authorization" => "Bot fake_bot_token" })
      .to_return(status: 204, body: "")

    assert DiscordApiClient.new(bot_token: "fake_bot_token")
                           .add_guild_member_role("guild_id", "user_id", "role_id")
  end

  test "#remove_guild_member_role remove cargo com bot token" do
    stub_request(:delete, "https://discord.com/api/v10/guilds/guild_id/members/user_id/roles/role_id")
      .with(headers: { "Authorization" => "Bot fake_bot_token" })
      .to_return(status: 204, body: "")

    assert DiscordApiClient.new(bot_token: "fake_bot_token")
                           .remove_guild_member_role("guild_id", "user_id", "role_id")
  end

  test "#add_guild_member_role retorna false sem bot token" do
    assert_not DiscordApiClient.new(bot_token: nil)
                               .add_guild_member_role("guild_id", "user_id", "role_id")
  end

  test "#refresh_access_token renova token via OAuth" do
    Rails.application.credentials.stubs(:dig).with(:discord, :client_id).returns("client_id")
    Rails.application.credentials.stubs(:dig).with(:discord, :client_secret).returns("client_secret")
    stub_request(:post, "https://discord.com/api/oauth2/token")
      .with { |request| URI.decode_www_form(request.body).to_h.slice("grant_type", "refresh_token") == { "grant_type" => "refresh_token", "refresh_token" => "refresh_token" } }
      .to_return(
        status: 200,
        body: {
          access_token: "new_access",
          refresh_token: "new_refresh",
          expires_in: 3600
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    token_data = DiscordApiClient.new(bot_token: nil).refresh_access_token("refresh_token")

    assert_equal "new_access", token_data["access_token"]
    assert_equal "new_refresh", token_data["refresh_token"]
  end
end
