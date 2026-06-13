require "application_system_test_case"

class RestrictedAccessFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:five)
    @user.update!(squad: nil)
  end

  test "member without the required role lands on the restricted page and cannot reach the dashboard" do
    system_sign_in_without_access(@user)

    assert_current_path restricted_access_path
    assert_text "ACESSO_RESTRITO"
    assert_text "Permissões insuficientes para acessar os recursos internos"

    assert_not @user.reload.has_guild_access, "esperava que o membro ficasse sem acesso à guild"

    visit dashboard_path
    assert_current_path restricted_access_path
    assert_text "ACESSO_RESTRITO"
  end
end
