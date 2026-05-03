require "test_helper"

class PublicRankingsControllerTest < ActionDispatch::IntegrationTest
  test "ranking público abre sem login" do
    get public_guild_rankings_path(guilds(:one), ranking_id: rankings(:user_xp).id)

    assert_response :success
    assert_includes response.body, guilds(:one).name
    assert_includes response.body, rankings(:user_xp).name
  end
end
