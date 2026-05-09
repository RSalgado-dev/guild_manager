require "test_helper"
require "ostruct"

class ActiveAdminPermissionAdapterTest < ActiveSupport::TestCase
  test "cargo máximo tem acesso total ao ActiveAdmin" do
    adapter = adapter_for(users(:one), Role)

    assert adapter.authorized?(:read, Role)
    assert adapter.authorized?(:destroy, roles(:one))
  end

  test "usuário com permissão operacional não acessa ActiveAdmin" do
    adapter = adapter_for(users(:two), Role)

    assert_not adapter.authorized?(:read, Squad)
    assert_not adapter.authorized?(:read, Event)
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

  test "escopo de pedidos da loja limita pela guilda do item" do
    item_one = StoreItem.create!(guild: guilds(:one), name: "Item guilda um", price: 10)
    item_two = StoreItem.create!(guild: guilds(:two), name: "Item guilda dois", price: 10)
    order_one = StoreOrder.create!(user: users(:two), store_item: item_one)
    StoreOrder.create!(user: users(:three), store_item: item_two)
    adapter = adapter_for(users(:two), StoreOrder)

    assert_equal [ order_one.id ], adapter.scope_collection(StoreOrder.all).pluck(:id)
  end

  private

  def adapter_for(user, resource_class)
    ActiveAdminPermissionAdapter.new(OpenStruct.new(resource_class: resource_class), user)
  end
end
