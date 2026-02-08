require "test_helper"

class GuildTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    guild = Guild.new(
      name: "Guilda de Teste",
      description: "Uma guilda para testes",
      discord_guild_id: "123456789012345678"
    )
    assert guild.valid?
  end

  test "não deve ser válido sem nome" do
    guild = Guild.new(description: "Uma guilda sem nome")
    assert_not guild.valid?
    assert_includes guild.errors[:name], "can't be blank"
  end

  test "não deve ser válido com nome muito longo" do
    guild = Guild.new(name: "a" * 101)
    assert_not guild.valid?
    assert_includes guild.errors[:name], "is too long (maximum is 100 characters)"
  end

  test "deve ser válido sem descrição" do
    guild = Guild.new(name: "Guilda sem descrição", discord_guild_id: "123456789")
    assert guild.valid?
  end

  test "não deve ser válido sem discord_guild_id" do
    guild = Guild.new(name: "Guilda de Teste")
    assert_not guild.valid?
    assert_includes guild.errors[:discord_guild_id], "can't be blank"
  end

  test "não deve ser válido com discord_guild_id duplicado" do
    guild = Guild.new(
      name: "Nova Guilda",
      discord_guild_id: guilds(:one).discord_guild_id
    )
    assert_not guild.valid?
    assert_includes guild.errors[:discord_guild_id], "has already been taken"
  end

  test "deve ser válido sem required_discord_role_id" do
    guild = Guild.new(
      name: "Guilda sem role obrigatório",
      discord_guild_id: "987654321"
    )
    assert guild.valid?
  end

  test "deve armazenar required_discord_role_id e required_discord_role_name" do
    guild = Guild.create!(
      name: "Guilda com role",
      discord_guild_id: "111222333444",
      required_discord_role_id: "555666777888",
      required_discord_role_name: "Membro Verificado"
    )
    assert_equal "555666777888", guild.required_discord_role_id
    assert_equal "Membro Verificado", guild.required_discord_role_name
  end

  # === Relacionamentos ===

  test "deve ter muitos usuários" do
    guild = guilds(:one)
    assert_respond_to guild, :users
  end

  test "deve ter muitos cargos" do
    guild = guilds(:one)
    assert_respond_to guild, :roles
  end

  test "deve ter muitos esquadrões" do
    guild = guilds(:one)
    assert_respond_to guild, :squads
  end

  test "deve destruir dependências ao ser destruída" do
    guild = guilds(:one)
    role_count = guild.roles.count
    user_count = guild.users.count
    event_count = guild.events.count
    squad_count = guild.squads.count

    assert role_count > 0, "Deve ter pelo menos um role"
    assert user_count > 0, "Deve ter pelo menos um usuário"

    guild.destroy

    # Verifica que roles, users, events e squads foram destruídos
    assert_equal 0, Role.where(guild_id: guild.id).count
    assert_equal 0, User.where(guild_id: guild.id).count
    assert_equal 0, Event.where(guild_id: guild.id).count
    assert_equal 0, Squad.where(guild_id: guild.id).count
  end
end
