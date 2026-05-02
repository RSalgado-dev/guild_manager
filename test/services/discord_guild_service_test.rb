require "test_helper"

class DiscordGuildServiceTest < ActiveSupport::TestCase
  test ".sync_guild usa token das credenciais quando token nao e informado" do
    Rails.application.credentials.stubs(:dig).with(:discord, :bot_token).returns("fake_bot_token")
    discord_guild_id = "333333333333333333"

    stub_request(:get, "https://discord.com/api/v10/guilds/#{discord_guild_id}")
      .with(headers: { "Authorization" => "Bot fake_bot_token" })
      .to_return(
        status: 200,
        body: {
          id: discord_guild_id,
          name: "Guilda Sincronizada",
          icon: "icon_hash"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    guild = DiscordGuildService.sync_guild(discord_guild_id)

    assert_equal "Guilda Sincronizada", guild.name
    assert_equal "Guilda Sincronizada", guild.discord_name
    assert_equal "https://cdn.discordapp.com/icons/#{discord_guild_id}/icon_hash.png", guild.discord_icon_url
  end
end
