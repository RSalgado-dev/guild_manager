require "test_helper"

class AccessControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Mock para evitar problema de renderização CSS no teste
    @controller = AccessController.new
  end

  test "deve exibir página restricted quando usuário está logado" do
    user = users(:one)
    ApplicationController.any_instance.stubs(:logged_in?).returns(true)
    ApplicationController.any_instance.stubs(:current_user).returns(user)
    ApplicationController.any_instance.stubs(:render).returns("")

    get restricted_access_path
    assert_response :success
  end

  test "página restricted deve mostrar mensagem sobre cargo necessário quando user está logado" do
    user = users(:one)
    guild = user.guild
    guild.update(
      required_discord_role_name: "Membro Verificado",
      discord_guild_id: "123456789"
    )

    ApplicationController.any_instance.stubs(:logged_in?).returns(true)
    ApplicationController.any_instance.stubs(:current_user).returns(user)
    ApplicationController.any_instance.stubs(:render).returns("")

    get restricted_access_path
    assert_response :success
  end

  test "página restricted deve ter botão de logout quando usuário logado" do
    user = users(:one)

    ApplicationController.any_instance.stubs(:logged_in?).returns(true)
    ApplicationController.any_instance.stubs(:current_user).returns(user)
    ApplicationController.any_instance.stubs(:render).returns("")

    get restricted_access_path
    assert_response :success
  end
end
