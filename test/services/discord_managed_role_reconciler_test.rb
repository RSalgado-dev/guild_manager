require "test_helper"

class DiscordManagedRoleReconcilerTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :added_roles, :removed_roles

    def initialize(member_roles:)
      @member_roles = member_roles
      @added_roles = []
      @removed_roles = []
    end

    def bot_token?
      true
    end

    def guild_member(_discord_guild_id, discord_user_id)
      { "roles" => @member_roles.fetch(discord_user_id, []) }
    end

    def add_guild_member_role(discord_guild_id, discord_user_id, discord_role_id)
      @added_roles << [ discord_guild_id, discord_user_id, discord_role_id ]
      true
    end

    def remove_guild_member_role(discord_guild_id, discord_user_id, discord_role_id)
      @removed_roles << [ discord_guild_id, discord_user_id, discord_role_id ]
      true
    end
  end

  test "adiciona no Discord role gerenciada presente no app" do
    user = users(:five)
    guild = user.guild
    role = managed_role(guild, "Titulo Mestre", "131313131313131313")
    user.user_roles.create!(role:)
    client = FakeClient.new(member_roles: { user.discord_id => [ guild.required_discord_role_id ] })

    assert_difference -> { AuditLog.where(action: "discord_managed_role_added").count }, 1 do
      assert DiscordManagedRoleReconciler.call(guild:, user:, client:)
    end

    assert_equal [ [ guild.discord_guild_id, user.discord_id, role.discord_role_id ] ], client.added_roles
    assert_empty client.removed_roles
    assert_not_nil user.reload.discord_roles_synced_at
  end

  test "remove do Discord role gerenciada ausente no app" do
    user = users(:five)
    guild = user.guild
    role = managed_role(guild, "Titulo Antigo", "141414141414141414")
    client = FakeClient.new(member_roles: { user.discord_id => [ role.discord_role_id ] })

    assert_difference -> { AuditLog.where(action: "discord_managed_role_removed").count }, 1 do
      assert DiscordManagedRoleReconciler.call(guild:, user:, client:)
    end

    assert_empty client.added_roles
    assert_equal [ [ guild.discord_guild_id, user.discord_id, role.discord_role_id ] ], client.removed_roles
  end

  test "nao remove roles externas nao gerenciadas pelo app" do
    user = users(:five)
    guild = user.guild
    unmanaged_role = Role.create!(
      guild: guild,
      name: "Role Externa",
      description: "Role Externa",
      category: "special",
      managed_by_app: false,
      discord_role_id: "151515151515151515"
    )
    client = FakeClient.new(member_roles: { user.discord_id => [ unmanaged_role.discord_role_id ] })

    assert DiscordManagedRoleReconciler.call(guild:, user:, client:)
    assert_empty client.added_roles
    assert_empty client.removed_roles
  end

  private

  def managed_role(guild, name, discord_role_id)
    Role.create!(
      guild: guild,
      name: name,
      description: name,
      category: "cosmetic",
      managed_by_app: true,
      discord_role_id: discord_role_id
    )
  end
end
