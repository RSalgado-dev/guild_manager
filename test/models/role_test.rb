require "test_helper"

class RoleTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    role = Role.new(
      guild: guilds(:one),
      name: "Cargo de Teste",
      description: "Um cargo para testes",
      category: "cosmetic",
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

  # === Métodos ===

  test "#admin? deve retornar true quando is_admin é true" do
    role = roles(:one) # fixture 'one' tem is_admin: true
    assert role.admin?
  end

  test "#admin? deve retornar true para categoria administrativa" do
    role = Role.new(
      guild: guilds(:one),
      name: "Logística",
      category: "administrative",
      is_admin: false
    )

    assert role.admin?
  end

  test "#admin? deve retornar true para categoria máxima" do
    role = Role.new(
      guild: guilds(:one),
      name: "Guild Master",
      category: "role_maximum",
      is_admin: false
    )

    assert role.admin?
  end

  test "#admin? deve retornar false quando is_admin é false" do
    role = roles(:two) # fixture 'two' tem is_admin: false
    assert_not role.admin?
  end

  test "deve validar categoria de cargo" do
    role = roles(:two)
    role.category = "invalid"

    assert_not role.valid?
    assert_includes role.errors[:category], "is not included in the list"
  end

  test "#category_label deve retornar rótulo humano" do
    assert_equal "Cargo base", roles(:two).category_label
    assert_equal "Administrativo", roles(:one).category_label
    assert_equal "Máximo", Role.new(category: "role_maximum").category_label
  end
end
