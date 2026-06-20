require "test_helper"

class Manage::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "cargo máximo acessa área de gestão" do
    sign_in(users(:one))

    get manage_root_path

    assert_response :success
    assert_includes response.body, "Gestão da Guilda"
    assert_includes response.body, "Guild Manager"
  end

  test "usuário com permissão delegada acessa gestão mas não ActiveAdmin" do
    sign_in(users(:two))

    get manage_root_path
    assert_response :success

    get admin_root_path
    assert_redirected_to root_path
  end

  test "usuário sem permissão não acessa gestão" do
    sign_in(users(:five))
    PermissionGroupRole.where(role: roles(:two)).destroy_all
    users(:five).update!(has_guild_access: true)
    User.any_instance.stubs(:sync_discord_roles_if_stale!).returns(false)

    get manage_root_path

    assert_redirected_to dashboard_path
  end
end
