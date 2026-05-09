require "test_helper"

module Access
  class StoreOrdersControllerTest < ActionDispatch::IntegrationTest
    test "member creates order from store item" do
      user = users(:five)
      user.update!(currency_balance: 50)
      item = StoreItem.create!(guild: user.guild, name: "Passe semanal", price: 25, stock_quantity: 2)

      sign_in(user)

      assert_difference -> { StoreOrder.where(user: user, store_item: item).count }, 1 do
        post store_orders_path, params: { store_item_id: item.id }
      end

      assert_redirected_to store_orders_path
      assert_equal 25, user.reload.currency_balance
      assert_equal 1, item.reload.stock_quantity
    end

    test "member cannot create order without enough currency" do
      user = users(:five)
      user.update!(currency_balance: 5)
      item = StoreItem.create!(guild: user.guild, name: "Passe mensal", price: 25, stock_quantity: 2)

      sign_in(user)

      assert_no_difference -> { StoreOrder.count } do
        post store_orders_path, params: { store_item_id: item.id }
      end

      assert_redirected_to store_path
      assert_equal 5, user.reload.currency_balance
      assert_equal 2, item.reload.stock_quantity
    end

    test "member cancels pending order and receives refund" do
      user = users(:five)
      user.update!(currency_balance: 60)
      item = StoreItem.create!(guild: user.guild, name: "Ticket de treino", price: 20, stock_quantity: 1)
      order = StoreOrder.checkout!(user: user, store_item: item)

      sign_in(user)

      assert_difference -> { CurrencyTransaction.credits.count }, 1 do
        post cancel_store_order_path(order)
      end

      assert_redirected_to store_orders_path
      assert_equal "canceled", order.reload.status
      assert_equal 60, user.reload.currency_balance
      assert_equal 1, item.reload.stock_quantity
    end

    test "orders page uses visible action links on dark background" do
      user = users(:five)

      sign_in(user)
      get store_orders_path

      assert_response :success
      assert_includes response.body, "text-neon-cyan"
      assert_not_includes response.body, "text-black"
    end
  end
end
