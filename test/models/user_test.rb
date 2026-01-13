require "test_helper"

class UserTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    user = User.new(
      guild: guilds(:one),
      discord_id: "999999999999999999",
      discord_username: "test_user",
      xp_points: 100,
      currency_balance: 500
    )
    assert user.valid?
  end

  test "não deve ser válido sem discord_id" do
    user = User.new(guild: guilds(:one), discord_username: "test_user")
    assert_not user.valid?
    assert_includes user.errors[:discord_id], "can't be blank"
  end

  test "não deve ser válido com discord_id duplicado" do
    user = User.new(
      guild: guilds(:one),
      discord_id: users(:one).discord_id
    )
    assert_not user.valid?
    assert_includes user.errors[:discord_id], "has already been taken"
  end

  test "não deve ser válido com xp_points negativo" do
    user = User.new(
      guild: guilds(:one),
      discord_id: "888888888888888888",
      xp_points: -10
    )
    assert_not user.valid?
    assert_includes user.errors[:xp_points], "must be greater than or equal to 0"
  end

  test "não deve ser válido com currency_balance negativo" do
    user = User.new(
      guild: guilds(:one),
      discord_id: "888888888888888888",
      currency_balance: -50
    )
    assert_not user.valid?
    assert_includes user.errors[:currency_balance], "must be greater than or equal to 0"
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    user = users(:one)
    assert_respond_to user, :guild
    assert_instance_of Guild, user.guild
  end

  test "deve pertencer opcionalmente a um esquadrão" do
    user = users(:one)
    assert_respond_to user, :squad
  end

  test "deve ter muitos user_roles" do
    user = users(:one)
    assert_respond_to user, :user_roles
  end

  test "deve ter muitos cargos através de user_roles" do
    user = users(:one)
    assert_respond_to user, :roles
  end

  test "deve ter muitos audit_logs" do
    user = users(:one)
    assert_respond_to user, :audit_logs
  end

  # === Métodos ===

  test "#admin? deve retornar true quando usuário tem cargo admin" do
    user = users(:one) # tem role(:one) que é admin
    assert user.admin?
  end

  test "#admin? deve retornar false quando usuário não tem cargo admin" do
    user = users(:two) # tem role(:two) que não é admin
    assert_not user.admin?
  end

  test "#primary_role deve retornar o cargo primário" do
    user = users(:one)
    primary_role = user.primary_role
    assert_not_nil primary_role
    assert_instance_of Role, primary_role
  end

  test "#primary_role deve retornar primeiro cargo se não houver primário" do
    user = users(:one)
    # Remover flag primary de todos os cargos
    user.user_roles.update_all(primary: false)
    primary_role = user.primary_role
    assert_not_nil primary_role
  end
end
