require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    user_role = UserRole.new(
      user: users(:three),
      role: roles(:one),
      primary: false
    )
    assert user_role.valid?
  end

  test "não deve ser válido sem usuário" do
    user_role = UserRole.new(role: roles(:one))
    assert_not user_role.valid?
  end

  test "não deve ser válido sem cargo" do
    user_role = UserRole.new(user: users(:one))
    assert_not user_role.valid?
  end

  test "não deve permitir combinação duplicada de usuário e cargo" do
    # user_roles(:one) já tem user:one e role:one
    user_role = UserRole.new(
      user: users(:one),
      role: roles(:one)
    )
    assert_not user_role.valid?
    assert_includes user_role.errors[:user_id], "has already been taken"
  end

  test "deve permitir mesmo usuário com cargos diferentes" do
    user_role = UserRole.new(
      user: users(:two),
      role: roles(:one)
    )
    assert user_role.valid?
  end

  test "deve permitir mesmo cargo para usuários diferentes" do
    user_role = UserRole.new(
      user: users(:three),
      role: roles(:two)
    )
    assert user_role.valid?
  end

  # === Relacionamentos ===

  test "deve pertencer a um usuário" do
    user_role = user_roles(:one)
    assert_respond_to user_role, :user
    assert_instance_of User, user_role.user
  end

  test "deve pertencer a um cargo" do
    user_role = user_roles(:one)
    assert_respond_to user_role, :role
    assert_instance_of Role, user_role.role
  end

  # === Scopes ===

  test "scope primary deve retornar apenas cargos primários" do
    primary_roles = UserRole.primary
    assert primary_roles.all? { |ur| ur.primary == true }
    assert primary_roles.count > 0
  end

  test "scope primary não deve retornar cargos não primários" do
    primary_roles = UserRole.primary
    non_primary = user_roles(:four) # tem primary: false
    assert_not primary_roles.include?(non_primary)
  end

  # === Comportamento ===

  test "primary deve ser false por padrão" do
    user_role = UserRole.new(user: users(:three), role: roles(:one))
    assert_equal false, user_role.primary
  end

  test "deve permitir definir cargo como primário" do
    user_role = UserRole.new(
      user: users(:three),
      role: roles(:one),
      primary: true
    )
    assert user_role.valid?
    assert_equal true, user_role.primary
  end
end
