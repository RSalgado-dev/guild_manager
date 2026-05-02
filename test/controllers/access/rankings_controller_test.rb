require "test_helper"

class Access::RankingsControllerTest < ActionDispatch::IntegrationTest
  test "lista rankings ativos" do
    sign_in(users(:two))

    get rankings_path

    assert_response :success
    assert_includes response.body, rankings(:user_xp).name
    assert_includes response.body, rankings(:squad_members).name
    assert_not_includes response.body, rankings(:inactive).name
  end

  test "seleciona ranking por parâmetro" do
    sign_in(users(:two))

    get rankings_path(ranking_id: rankings(:squad_members).id)

    assert_response :success
    assert_includes response.body, "Membros por squad"
    assert_includes response.body, "Número de membros"
  end
end
