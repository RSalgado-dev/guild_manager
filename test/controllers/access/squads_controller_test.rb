require "test_helper"

module Access
  class SquadsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @manager = users(:two) # possui manage_members via role two
      @leader = users(:one)
      @invitee = users(:five)
      @squad = squads(:one)
    end

    test "usuário com manage_members pode abrir formulário de criação" do
      sign_in @manager
      get new_squad_path
      assert_response :success
    end

    test "usuário com manage_members pode criar squad e definir líder" do
      sign_in @manager

      assert_difference("Squad.count", 1) do
        post squads_path, params: {
          squad: {
            name: "Esquadrão Ômega",
            tag: "OMEGA",
            description: "Time de operações",
            leader_id: @invitee.id
          }
        }
      end

      created = Squad.order(:id).last
      assert_equal @invitee.id, created.leader_id
      assert_equal created.id, @invitee.reload.squad_id
    end

    test "líder pode solicitar alteração de perfil do squad" do
      sign_in @leader

      patch request_profile_change_squad_path(@squad), params: {
        squad: { name: "Alpha Prime", tag: "ALPPRM", description: "Nova descrição" }
      }

      assert_redirected_to squad_path(@squad)
      assert_equal "profile_pending", @squad.reload.profile_change_status
    end

    test "usuário com manage_members pode aprovar alteração pendente" do
      @squad.request_profile_change!(
        actor: @squad.leader,
        attributes: { name: "Alpha Prime", tag: "ALPPRM" }
      )

      sign_in @manager
      post approve_profile_change_squad_path(@squad)

      assert_redirected_to pending_reviews_squads_path
      assert_equal "profile_approved", @squad.reload.profile_change_status
      assert_equal "Alpha Prime", @squad.name
    end

    test "líder pode convidar usuário sem squad" do
      sign_in @leader

      assert_difference("SquadInvitation.count", 1) do
        post create_invitation_squad_path(@squad), params: { invitee_id: users(:six).id }
      end

      assert_redirected_to squad_path(@squad)
      assert_equal users(:six).id, SquadInvitation.last.invitee_id
    end
  end
end
