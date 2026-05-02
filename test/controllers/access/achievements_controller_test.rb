require "test_helper"

class Access::AchievementsControllerTest < ActionDispatch::IntegrationTest
  test "lista catálogo de conquistas ativas" do
    sign_in(users(:two))

    get achievements_path

    assert_response :success
    assert_includes response.body, achievements(:one).name
    assert_not_includes response.body, achievements(:inactive).name
  end

  test "exibe detalhe da conquista" do
    sign_in(users(:two))

    get achievement_path(achievements(:one))

    assert_response :success
    assert_includes response.body, achievements(:one).name
  end
end
