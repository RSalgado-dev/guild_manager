require "test_helper"

module Access
  class SquadsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @manager = users(:two) # possui manage_members via role two
      @leader = users(:one)
      @invitee = users(:five)
      @squad = squads(:one)
    end

    test "usuário lista squads e convites pendentes" do
      sign_in @invitee

      get squads_path

      assert_response :success
      assert_includes response.body, @squad.name
      assert_includes response.body, "Convites Recebidos"
    end

    test "usuário visualiza perfil do squad" do
      sign_in @leader

      get squad_path(@squad)

      assert_response :success
      assert_includes response.body, @squad.name
      assert_includes response.body, "Convidar Membro"
    end

    test "usuário com manage_members pode abrir formulário de criação" do
      sign_in @manager
      get new_squad_path
      assert_response :success
    end

    test "usuário sem manage_members não pode abrir criação" do
      sign_in @invitee
      User.any_instance.stubs(:has_permission?).with(:manage_members).returns(false)

      get new_squad_path

      assert_redirected_to dashboard_path
      assert_equal "❌ Você não tem permissão para gerenciar membros.", flash[:alert]
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

    test "criação de squad inválida renderiza formulário" do
      sign_in @manager

      assert_no_difference("Squad.count") do
        post squads_path, params: {
          squad: {
            name: "",
            tag: "X",
            description: "Sem líder",
            leader_id: ""
          }
        }
      end

      assert_response :unprocessable_entity
      assert_includes response.body, "Erro ao criar squad"
    end

    test "líder pode solicitar alteração de perfil do squad" do
      sign_in @leader

      patch request_profile_change_squad_path(@squad), params: {
        squad: { name: "Alpha Prime", tag: "ALPPRM", description: "Nova descrição" }
      }

      assert_redirected_to squad_path(@squad)
      assert_equal "profile_pending", @squad.reload.profile_change_status
    end

    test "membro que não é líder não pode solicitar alteração de perfil" do
      member = users(:four)
      sign_in member

      patch request_profile_change_squad_path(@squad), params: {
        squad: { name: "Alpha Bloqueado", tag: "ALPBLOQ", description: "Tentativa indevida" }
      }

      assert_redirected_to squad_path(@squad)
      assert_equal "❌ Apenas o líder do squad pode executar esta ação.", flash[:alert]
      assert_not_equal "profile_pending", @squad.reload.profile_change_status
    end

    test "solicitação sem alteração mostra erro para líder" do
      sign_in @leader

      patch request_profile_change_squad_path(@squad), params: {
        squad: { name: @squad.name, tag: @squad.tag, description: @squad.description }
      }

      assert_redirected_to squad_path(@squad)
      assert_equal "❌ Nenhuma alteração foi informada", flash[:alert]
      assert_not_equal "profile_pending", @squad.reload.profile_change_status
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

    test "usuário com manage_members visualiza revisões pendentes" do
      @squad.request_profile_change!(
        actor: @squad.leader,
        attributes: { name: "Alpha Review", tag: "ALPREV" }
      )

      sign_in @manager
      get pending_reviews_squads_path

      assert_response :success
      assert_includes response.body, "Alpha Review"
    end

    test "aprovar sem alteração pendente retorna erro" do
      sign_in @manager

      post approve_profile_change_squad_path(@squad)

      assert_redirected_to pending_reviews_squads_path
      assert_equal "❌ Sem alteração pendente para aprovação", flash[:alert]
    end

    test "usuário com manage_members pode rejeitar alteração pendente" do
      @squad.request_profile_change!(
        actor: @squad.leader,
        attributes: { name: "Alpha Rejeitado", tag: "ALPREJ" }
      )

      sign_in @manager
      post reject_profile_change_squad_path(@squad), params: { reason: "Nome fora do padrão" }

      assert_redirected_to pending_reviews_squads_path
      assert_equal "profile_rejected", @squad.reload.profile_change_status
      assert_equal "Nome fora do padrão", @squad.profile_change_rejection_reason
    end

    test "rejeitar sem motivo retorna erro" do
      @squad.request_profile_change!(
        actor: @squad.leader,
        attributes: { name: "Alpha Sem Motivo", tag: "ALPSM" }
      )

      sign_in @manager
      post reject_profile_change_squad_path(@squad), params: { reason: "" }

      assert_redirected_to pending_reviews_squads_path
      assert_equal "❌ Informe o motivo da rejeição", flash[:alert]
      assert_equal "profile_pending", @squad.reload.profile_change_status
    end

    test "líder pode convidar usuário sem squad" do
      sign_in @leader

      assert_difference("SquadInvitation.count", 1) do
        post create_invitation_squad_path(@squad), params: { invitee_id: users(:six).id }
      end

      assert_redirected_to squad_path(@squad)
      assert_equal users(:six).id, SquadInvitation.last.invitee_id
    end

    test "líder não pode convidar usuário que já está em squad" do
      sign_in @leader

      assert_no_difference("SquadInvitation.count") do
        post create_invitation_squad_path(@squad), params: { invitee_id: users(:two).id }
      end

      assert_redirected_to squad_path(@squad)
      assert_includes flash[:alert], "Não foi possível enviar convite"
    end
  end
end
