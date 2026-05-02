require "application_system_test_case"

class AdminAuditSmokeTest < ApplicationSystemTestCase
  setup do
    @admin = users(:one)
    @admin.update!(has_guild_access: true)
    AuditLog.record!(
      action: "smoke_admin_audit",
      actor: @admin,
      entity: @admin,
      metadata: { "origin" => "test", "result" => "success" }
    )
  end

  test "admin can open audit logs from active admin" do
    system_sign_in(@admin)

    visit admin_audit_logs_path

    assert_text "Audit Logs"
    assert_text "smoke_admin_audit"
  end

  private

  def system_sign_in(user)
    Rails.application.credentials.stubs(:dig).with(:discord, :bot_token).returns("fake_bot_token")
    stub_discord_user_guilds(
      access_token: user.discord_access_token || "fake_token",
      guilds: [ { "id" => user.guild.discord_guild_id, "name" => user.guild.name } ]
    )
    stub_discord_guild_member(
      guild_id: user.guild.discord_guild_id,
      user_id: user.discord_id,
      roles: [ user.guild.required_discord_role_id ]
    )
    stub_discord_guild_roles(
      guild_id: user.guild.discord_guild_id,
      roles: [
        {
          "id" => user.guild.required_discord_role_id,
          "name" => user.guild.required_discord_role_name || "Membro"
        }
      ]
    )

    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
      provider: "discord",
      uid: user.discord_id,
      info: {
        name: user.discord_username,
        email: user.email || "admin-smoke@example.com",
        image: user.discord_avatar_url
      },
      credentials: {
        token: user.discord_access_token || "fake_token",
        refresh_token: user.discord_refresh_token || "fake_refresh_token",
        expires_at: 1.week.from_now.to_i
      }
    )

    visit "/auth/discord/callback"
  end
end
