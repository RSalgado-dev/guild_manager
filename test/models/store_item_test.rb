require "test_helper"

class StoreItemTest < ActiveSupport::TestCase
  test "is valid with required attributes" do
    item = StoreItem.new(
      guild: guilds(:one),
      name: "Pacote VIP",
      price: 100,
      stock_quantity: nil
    )

    assert item.valid?
  end

  test "requires non-negative price and stock" do
    item = StoreItem.new(
      guild: guilds(:one),
      name: "Item inválido",
      price: -1,
      stock_quantity: -1
    )

    assert_not item.valid?
    assert item.errors[:price].any?
    assert item.errors[:stock_quantity].any?
  end

  test "available scope only includes active items with stock" do
    available = StoreItem.create!(guild: guilds(:one), name: "Disponível", price: 10, stock_quantity: 1)
    StoreItem.create!(guild: guilds(:one), name: "Sem estoque", price: 10, stock_quantity: 0)
    StoreItem.create!(guild: guilds(:one), name: "Inativo", price: 10, status: "inactive")

    assert_includes StoreItem.available, available
    assert_equal [ available.id ], StoreItem.available.where(guild: guilds(:one)).pluck(:id)
  end

  test "reserve and restore stock for finite items" do
    item = StoreItem.create!(guild: guilds(:one), name: "Poção", price: 10, stock_quantity: 1)

    item.reserve_stock!
    assert_equal 0, item.reload.stock_quantity
    assert_not item.in_stock?

    item.restore_stock!
    assert_equal 1, item.reload.stock_quantity
  end

  test "unlimited stock is not changed by reserve or restore" do
    item = StoreItem.create!(guild: guilds(:one), name: "Cargo cosmético", price: 25, stock_quantity: nil)

    item.reserve_stock!
    item.restore_stock!

    assert_nil item.reload.stock_quantity
    assert item.in_stock?
  end
end
