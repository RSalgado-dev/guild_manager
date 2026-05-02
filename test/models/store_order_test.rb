require "test_helper"

class StoreOrderTest < ActiveSupport::TestCase
  test "checkout debits currency and reserves stock" do
    user = users(:five)
    user.update!(currency_balance: 100)
    item = StoreItem.create!(guild: user.guild, name: "Baú raro", price: 40, stock_quantity: 2)
    order = nil

    assert_difference -> { StoreOrder.count }, 1 do
      assert_difference -> { CurrencyTransaction.debits.count }, 1 do
        assert_difference -> { AuditLog.where(action: "store_order_created").count }, 1 do
          order = StoreOrder.checkout!(user: user, store_item: item)
        end
      end
    end

    assert_equal "pending", order.status
    assert_equal 60, user.reload.currency_balance
    assert_equal 1, item.reload.stock_quantity
    assert_equal order, CurrencyTransaction.order(:created_at).last.reason
  end

  test "checkout rejects insufficient balance without changing stock" do
    user = users(:five)
    user.update!(currency_balance: 10)
    item = StoreItem.create!(guild: user.guild, name: "Montaria", price: 50, stock_quantity: 1)

    assert_no_difference -> { StoreOrder.count } do
      assert_no_difference -> { CurrencyTransaction.count } do
        assert_raises(ArgumentError) { StoreOrder.checkout!(user: user, store_item: item) }
      end
    end

    assert_equal 10, user.reload.currency_balance
    assert_equal 1, item.reload.stock_quantity
  end

  test "reject refunds currency and restores stock" do
    buyer = users(:five)
    reviewer = users(:one)
    buyer.update!(currency_balance: 80)
    item = StoreItem.create!(guild: buyer.guild, name: "Token de raid", price: 30, stock_quantity: 1)
    order = StoreOrder.checkout!(user: buyer, store_item: item)

    assert_difference -> { CurrencyTransaction.credits.count }, 1 do
      assert_difference -> { AuditLog.where(action: "store_order_rejected").count }, 1 do
        order.reject!(actor: reviewer, notes: "Sem disponibilidade")
      end
    end

    assert_equal "rejected", order.reload.status
    assert_equal reviewer, order.rejected_by
    assert_equal "Sem disponibilidade", order.admin_notes
    assert_equal 80, buyer.reload.currency_balance
    assert_equal 1, item.reload.stock_quantity
    assert order.refunded_at.present?
  end

  test "cancel refunds currency and cannot be repeated" do
    buyer = users(:five)
    buyer.update!(currency_balance: 80)
    item = StoreItem.create!(guild: buyer.guild, name: "Ticket arena", price: 20, stock_quantity: 1)
    order = StoreOrder.checkout!(user: buyer, store_item: item)

    assert_difference -> { CurrencyTransaction.credits.count }, 1 do
      order.cancel!(actor: buyer)
    end

    assert_equal "canceled", order.reload.status
    assert_equal buyer, order.canceled_by
    assert_equal 80, buyer.reload.currency_balance
    assert_equal 1, item.reload.stock_quantity

    assert_no_difference -> { CurrencyTransaction.credits.count } do
      assert_raises(ArgumentError) { order.cancel!(actor: buyer) }
    end
  end

  test "fulfill does not refund or restore stock" do
    buyer = users(:five)
    reviewer = users(:one)
    buyer.update!(currency_balance: 80)
    item = StoreItem.create!(guild: buyer.guild, name: "Skin exclusiva", price: 20, stock_quantity: 1)
    order = StoreOrder.checkout!(user: buyer, store_item: item)

    assert_no_difference -> { CurrencyTransaction.credits.count } do
      order.fulfill!(actor: reviewer, notes: "Entregue no Discord")
    end

    assert_equal "fulfilled", order.reload.status
    assert_equal reviewer, order.fulfilled_by
    assert_equal "Entregue no Discord", order.admin_notes
    assert_equal 60, buyer.reload.currency_balance
    assert_equal 0, item.reload.stock_quantity
  end

  test "free checkout does not create currency transaction" do
    buyer = users(:five)
    item = StoreItem.create!(guild: buyer.guild, name: "Brinde", price: 0, stock_quantity: 1)

    assert_difference -> { StoreOrder.count }, 1 do
      assert_no_difference -> { CurrencyTransaction.count } do
        StoreOrder.checkout!(user: buyer, store_item: item)
      end
    end
  end
end
