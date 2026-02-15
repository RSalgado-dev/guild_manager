require "test_helper"

module Access
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @user.update!(has_guild_access: true)
    end

    # Index Action (Landing Page)
    test "should get index when not logged in" do
      get root_path
      assert_response :success
      assert_select "h1", /GUILD SYSTEM/
    end

    test "should redirect to dashboard when logged in with access" do
      sign_in @user
      # Força sessão sem fazer nova requisição GET root_path
      # pois sign_in já redireciona baseado no has_guild_access
      assert_equal @user.id, session[:user_id]

      # Agora testa explicitamente o comportamento de index
      get root_path
      assert_redirected_to dashboard_path
    end

    test "should show index when logged in without guild access" do
      @user.update!(has_guild_access: false)
      # Usa sign_in com roles vazios (sem o role requerido)
      # Para isso, precisamos de um  método auxiliar
      sign_in_without_role(@user)

      get root_path
      assert_response :success
    end

    # Show Action (Dashboard)
    test "should get dashboard when logged in with access" do
      sign_in @user
      get dashboard_path
      assert_response :success
      assert_not_nil assigns(:user)
      assert_not_nil assigns(:guild)
    end

    test "should redirect to restricted when logged in without access" do
      @user.update!(has_guild_access: false)
      sign_in_without_role(@user)

      get dashboard_path
      assert_redirected_to restricted_access_path
    end

    test "should redirect to root when not logged in" do
      get dashboard_path
      assert_redirected_to root_path
      assert_equal "Você precisa estar logado para acessar esta página.", flash[:alert]
    end

    test "dashboard should load user and guild" do
      sign_in @user
      get dashboard_path
      assert_not_nil assigns(:user)
      assert_not_nil assigns(:guild)
    end

    # Restricted Action
    test "should get restricted page when logged in without access" do
      @user.update!(has_guild_access: false)
      sign_in_without_role(@user)

      get restricted_access_path
      assert_response :success
      assert_not_nil assigns(:user)
      assert_not_nil assigns(:guild)
    end

    test "restricted should redirect when not logged in" do
      get restricted_access_path
      assert_redirected_to root_path
      assert_equal "Você precisa estar logado para acessar esta página.", flash[:alert]
    end

    test "restricted page should show guild information" do
      @user.update!(has_guild_access: false)
      sign_in_without_role(@user)

      get restricted_access_path
      assert_response :success
      assert_match @user.guild.name, response.body
    end
  end
end
