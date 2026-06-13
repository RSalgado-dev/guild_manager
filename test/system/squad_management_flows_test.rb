require "application_system_test_case"

class SquadManagementFlowsTest < ApplicationSystemTestCase
  setup do
    # users(:two) possui manage_members; users(:one) é líder do squad one.
    @manager = users(:two)
    @leader = users(:one)
    @squad = squads(:one)
  end

  test "manager creates a squad and assigns a squad-less leader" do
    new_leader = users(:six)
    new_leader.update!(squad: nil)

    system_sign_in(@manager, visit_after_sign_in: squads_path)

    click_link "Novo Squad"
    assert_text "Criar Squad"

    fill_in "Nome", with: "Esquadrão Sistema"
    fill_in "TAG", with: "SYS"
    fill_in "Descrição", with: "Squad criado pelo fluxo de sistema."
    select "#{new_leader.discord_username} (ID: #{new_leader.id})", from: "squad_leader_id"

    click_button "Criar Squad"

    assert_text "Squad criado com sucesso"
    assert_text "Esquadrão Sistema [SYS]"

    created = Squad.order(:id).last
    assert_equal "Esquadrão Sistema", created.name
    assert_equal new_leader.id, created.leader_id
    assert_equal created.id, new_leader.reload.squad_id
  end

  test "squad leader invites a member without a squad" do
    invitee = users(:six)
    invitee.update!(squad: nil)

    system_sign_in(@leader)
    visit squad_path(@squad)

    assert_text "Convidar Membro"
    select invitee.discord_username, from: "invitee_id"

    assert_difference -> { @squad.squad_invitations.count }, 1 do
      click_button "Enviar convite"
      assert_text "Convite enviado para #{invitee.discord_username}"
    end

    invitation = @squad.squad_invitations.order(:created_at).last
    assert_equal invitee.id, invitation.invitee_id
    assert_equal @leader.id, invitation.inviter_id
  end

  test "manager approves a pending squad profile change" do
    @squad.request_profile_change!(
      actor: @squad.leader,
      attributes: { name: "Alpha Aprovado", tag: "ALPAPR" }
    )

    system_sign_in(@manager, visit_after_sign_in: squads_path)

    click_link "Revisões Pendentes"
    assert_text "Revisões de Squads"
    assert_text "Alpha Aprovado"

    click_button "Aprovar"

    assert_text "Alteração aprovada"
    assert_equal "profile_approved", @squad.reload.profile_change_status
    assert_equal "Alpha Aprovado", @squad.name
  end

  test "manager rejects a pending squad profile change with a reason" do
    @squad.request_profile_change!(
      actor: @squad.leader,
      attributes: { name: "Alpha Rejeitado", tag: "ALPREJ" }
    )

    system_sign_in(@manager, visit_after_sign_in: pending_reviews_squads_path)

    assert_text "Alpha Rejeitado"
    fill_in "reason", with: "Nome fora do padrão da guilda"
    click_button "Rejeitar"

    assert_text "Alteração rejeitada"
    assert_equal "profile_rejected", @squad.reload.profile_change_status
    assert_equal "Nome fora do padrão da guilda", @squad.profile_change_rejection_reason
    assert_not_equal "Alpha Rejeitado", @squad.name
  end
end
