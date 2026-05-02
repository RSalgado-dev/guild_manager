require "test_helper"

class DiscordGuildRolesSyncTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:roles_data, keyword_init: true) do
    def bot_token?
      true
    end

    def guild_roles(_discord_guild_id)
      roles_data
    end
  end

  test "importa roles da guilda do Discord" do
    guild = guilds(:one)
    client = FakeClient.new(
      roles_data: [
        { "id" => guild.discord_guild_id, "name" => "@everyone" },
        { "id" => "909090909090909090", "name" => "Artesao" }
      ]
    )

    assert_difference -> { Role.count }, 1 do
      assert DiscordGuildRolesSync.call(guild:, client:)
    end

    role = guild.roles.find_by!(discord_role_id: "909090909090909090")
    assert_equal "Artesao", role.name
    assert_not role.managed_by_app
  end

  test "atualiza nome sem alterar controle do app" do
    guild = guilds(:one)
    role = Role.create!(
      guild: guild,
      name: "Nome Antigo",
      description: "Nome Antigo",
      category: "special",
      managed_by_app: true,
      discord_role_id: "919191919191919191"
    )
    client = FakeClient.new(
      roles_data: [
        { "id" => role.discord_role_id, "name" => "Nome Novo" }
      ]
    )

    assert_difference -> { AuditLog.where(action: "discord_role_updated").count }, 1 do
      assert DiscordGuildRolesSync.call(guild:, client:)
    end

    role.reload
    assert_equal "Nome Novo", role.name
    assert_equal "special", role.category
    assert role.managed_by_app
  end

  test "retorna false sem bot token" do
    client = Struct.new(:roles_data, keyword_init: true) do
      def bot_token?
        false
      end
    end.new(roles_data: [])

    assert_not DiscordGuildRolesSync.call(guild: guilds(:one), client:)
  end
end
