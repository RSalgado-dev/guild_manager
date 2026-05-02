require "test_helper"

module Access
  class StoreControllerTest < ActionDispatch::IntegrationTest
    test "member sees available store items" do
      user = users(:five)
      item = StoreItem.create!(guild: user.guild, name: "Poção lendária", price: 15, stock_quantity: 3)
      StoreItem.create!(guild: user.guild, name: "Item inativo", price: 15, status: "inactive")

      sign_in(user)
      get store_path

      assert_response :success
      assert_includes response.body, item.name
      assert_not_includes response.body, "Item inativo"
      assert_includes response.body, "Meus pedidos"
    end
  end
end
