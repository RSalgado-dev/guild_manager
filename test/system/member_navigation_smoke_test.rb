require "application_system_test_case"

class MemberNavigationSmokeTest < ApplicationSystemTestCase
  setup do
    @user = users(:five)
    @user.update!(has_guild_access: true, currency_balance: 100)
    @item = StoreItem.create!(guild: @user.guild, name: "Passe Smoke", price: 25, stock_quantity: 2)
    Ranking.create!(
      guild: @user.guild,
      name: "XP Smoke",
      ranking_scope: "users",
      metric: "user_xp",
      entries_limit: 5,
      active: true
    )
  end

  test "member navigates dashboard, store, orders and rankings" do
    system_sign_in(@user)

    assert_text "GUILD SYSTEM"
    assert_link "Eventos"
    assert_link "Missões"
    assert_link "Rankings"
    assert_link "Loja"

    click_link "Loja"
    assert_text "Loja da Guild"
    assert_text @item.name

    click_button "Comprar por 25 moedas"
    assert_text "Meus pedidos"
    assert_text @item.name
    assert_text "pending"

    click_link "Rankings"
    assert_text "Rankings"
    assert_text "XP Smoke"
  end
end
