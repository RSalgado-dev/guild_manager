require "test_helper"
require "ostruct"

class ActiveAdminPermissionAdapterTest < ActiveSupport::TestCase
  test "superadmin tem acesso total" do
    adapter = adapter_for(users(:one), Role)

    assert adapter.authorized?(:read, Role)
    assert adapter.authorized?(:destroy, roles(:one))
  end

  test "usuário com permissão operacional acessa apenas recurso correspondente" do
    adapter = adapter_for(users(:two), Role)

    assert adapter.authorized?(:read, Squad)
    assert adapter.authorized?(:read, Event)
    assert_not adapter.authorized?(:read, Role)
  end

  test "cargo administrativo exige permissão específica" do
    adapter = adapter_for(users(:two), Role)

    assert_not adapter.authorized?(:update, roles(:one))
  end

  test "escopo de coleção limita recursos por guilda" do
    adapter = adapter_for(users(:two), User)

    assert_equal [ guilds(:one).id ], adapter.scope_collection(User.all).distinct.pluck(:guild_id)
  end

  private

  def adapter_for(user, resource_class)
    ActiveAdminPermissionAdapter.new(OpenStruct.new(resource_class: resource_class), user)
  end
end
