require "test_helper"

class DiscordMemberRoleSyncTest < ActiveSupport::TestCase
  test "sincroniza roles do Discord para roles locais do usuário" do
    user = users(:five)
    guild = user.guild
    discord_role_id = "777777777777777777"

    stub_discord_guild_member(
      guild_id: guild.discord_guild_id,
      user_id: user.discord_id,
      roles: [ guild.required_discord_role_id, discord_role_id ]
    )
    stub_discord_guild_roles(
      guild_id: guild.discord_guild_id,
      roles: [
        { "id" => guild.required_discord_role_id, "name" => guild.required_discord_role_name },
        { "id" => discord_role_id, "name" => "Artesão" }
      ]
    )

    assert DiscordMemberRoleSync.call(user:, guild:, client: DiscordApiClient.new(bot_token: "fake_bot_token"))

    assert user.reload.has_guild_access
    assert user.roles.exists?(discord_role_id:)
    assert_not_nil user.discord_roles_synced_at
  end

  test "retorna false sem bot token" do
    user = users(:five)

    assert_not DiscordMemberRoleSync.call(
      user: user,
      guild: user.guild,
      client: DiscordApiClient.new(bot_token: nil)
    )
  end

  test "preserva roles gerenciadas pelo app ausentes no Discord" do
    user = users(:five)
    guild = user.guild
    managed_role = Role.create!(
      guild: guild,
      name: "Cor Vermelha",
      description: "Cor Vermelha",
      category: "cosmetic",
      managed_by_app: true,
      discord_role_id: "888888888888888888"
    )
    user.user_roles.create!(role: managed_role)

    stub_discord_guild_member(
      guild_id: guild.discord_guild_id,
      user_id: user.discord_id,
      roles: [ guild.required_discord_role_id ]
    )
    stub_discord_guild_roles(
      guild_id: guild.discord_guild_id,
      roles: [
        { "id" => guild.required_discord_role_id, "name" => guild.required_discord_role_name }
      ]
    )

    assert DiscordMemberRoleSync.call(user:, guild:, client: DiscordApiClient.new(bot_token: "fake_bot_token"))
    assert user.reload.roles.exists?(id: managed_role.id)
  end

  test "registra auditoria ao importar novo cargo do usuario" do
    user = users(:six)
    guild = user.guild
    discord_role_id = "121212121212121212"

    stub_discord_guild_member(
      guild_id: guild.discord_guild_id,
      user_id: user.discord_id,
      roles: [ guild.required_discord_role_id, discord_role_id ]
    )
    stub_discord_guild_roles(
      guild_id: guild.discord_guild_id,
      roles: [
        { "id" => guild.required_discord_role_id, "name" => guild.required_discord_role_name },
        { "id" => discord_role_id, "name" => "Explorador" }
      ]
    )

    assert_difference -> { AuditLog.where(action: "discord_user_role_assigned").count }, 2 do
      assert DiscordMemberRoleSync.call(user:, guild:, client: DiscordApiClient.new(bot_token: "fake_bot_token"))
    end
  end
end
