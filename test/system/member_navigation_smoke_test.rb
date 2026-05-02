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

  private

  def system_sign_in(user)
    Rails.application.credentials.stubs(:dig).with(:discord, :bot_token).returns("fake_bot_token")
    stub_discord_user_guilds(
      access_token: user.discord_access_token || "fake_token",
      guilds: [ { "id" => user.guild.discord_guild_id, "name" => user.guild.name } ]
    )
    stub_discord_guild_member(
      guild_id: user.guild.discord_guild_id,
      user_id: user.discord_id,
      roles: [ user.guild.required_discord_role_id ]
    )
    stub_discord_guild_roles(
      guild_id: user.guild.discord_guild_id,
      roles: [
        {
          "id" => user.guild.required_discord_role_id,
          "name" => user.guild.required_discord_role_name || "Membro"
        }
      ]
    )

    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
      provider: "discord",
      uid: user.discord_id,
      info: {
        name: user.discord_username,
        email: user.email || "smoke@example.com",
        image: user.discord_avatar_url
      },
      credentials: {
        token: user.discord_access_token || "fake_token",
        refresh_token: user.discord_refresh_token || "fake_refresh_token",
        expires_at: 1.week.from_now.to_i
      }
    )

    visit "/auth/discord/callback"
    visit dashboard_path
  end
end
