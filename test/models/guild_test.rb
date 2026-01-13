require "test_helper"

class GuildTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    guild = Guild.new(name: "Guilda de Teste", description: "Uma guilda para testes")
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
    guild = Guild.new(name: "Guilda sem descrição")
    assert guild.valid?
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
