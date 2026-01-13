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

  test "deve destruir cargos ao ser destruída" do
    guild = guilds(:one)
    role_count = guild.roles.count
    assert_difference("Role.count", -role_count) do
      guild.destroy
    end
  end

  test "deve anular a referência de usuários ao ser destruída" do
    guild = guilds(:one)
    user = guild.users.first
    guild.destroy
    user.reload
    assert_nil user.guild_id
  end
end
