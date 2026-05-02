require "test_helper"

class Access::MissionRequestsControllerTest < ActionDispatch::IntegrationTest
  test "usuário com cargo especial cria requisição de missão" do
    user = users(:five)
    sign_in(user)
    special_role = Role.create!(
      guild: user.guild,
      name: "Artesao",
      category: "special",
      managed_by_app: true
    )
    user.user_roles.create!(role: special_role)

    assert_difference -> { MissionRequest.where(requester: user).count }, 1 do
      assert_difference -> { AuditLog.where(action: "mission_request_created").count }, 1 do
        post mission_requests_path, params: {
          mission_request: {
            title: "Coleta de couro",
            description: "Preciso de couro raro para crafting."
          }
        }
      end
    end

    assert_redirected_to missions_path
  end

  test "usuário sem cargo especial não acessa requisição" do
    user = users(:five)
    sign_in(user)

    get new_mission_request_path

    assert_redirected_to missions_path
    assert_equal "❌ Seu cargo não permite requisitar missões.", flash[:alert]
  end
end
