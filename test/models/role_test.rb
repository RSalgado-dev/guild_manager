require "test_helper"

class RoleTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    role = Role.new(
      guild: guilds(:one),
      name: "Cargo de Teste",
      description: "Um cargo para testes",
      is_admin: false
    )
    assert role.valid?
  end

  test "não deve ser válido sem nome" do
    role = Role.new(guild: guilds(:one), description: "Sem nome")
    assert_not role.valid?
    assert_includes role.errors[:name], "can't be blank"
  end

  test "não deve ser válido com nome muito longo" do
    role = Role.new(guild: guilds(:one), name: "a" * 51)
    assert_not role.valid?
    assert_includes role.errors[:name], "is too long (maximum is 50 characters)"
  end

  test "não deve ser válido sem guilda" do
    role = Role.new(name: "Cargo sem guilda")
    assert_not role.valid?
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    role = roles(:one)
    assert_respond_to role, :guild
    assert_instance_of Guild, role.guild
  end

  test "deve ter muitos user_roles" do
    role = roles(:one)
    assert_respond_to role, :user_roles
  end

  test "deve ter muitos usuários através de user_roles" do
    role = roles(:one)
    assert_respond_to role, :users
  end

  test "deve destruir user_roles ao ser destruído" do
    role = roles(:one)
    user_role_count = role.user_roles.count
    assert_difference("UserRole.count", -user_role_count) do
      role.destroy
    end
  end

  # === Métodos ===

  test "#admin? deve retornar true quando is_admin é true" do
    role = roles(:one) # fixture 'one' tem is_admin: true
    assert role.admin?
  end

  test "#admin? deve retornar false quando is_admin é false" do
    role = roles(:two) # fixture 'two' tem is_admin: false
    assert_not role.admin?
  end
end
