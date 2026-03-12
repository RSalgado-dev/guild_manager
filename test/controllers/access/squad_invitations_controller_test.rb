require "test_helper"

module Access
  class SquadInvitationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @invitee = users(:five)
      @invitation = squad_invitations(:one_pending)
    end

    test "convidado pode aceitar convite e entrar no squad" do
      sign_in @invitee

      post accept_squad_invitation_path(@invitation)

      assert_redirected_to squad_path(@invitation.squad)
      assert_equal "accepted", @invitation.reload.status
      assert_equal @invitation.squad_id, @invitee.reload.squad_id
    end

    test "convidado pode recusar convite" do
      sign_in @invitee

      post decline_squad_invitation_path(@invitation)

      assert_redirected_to squads_path
      assert_equal "declined", @invitation.reload.status
    end
  end
end
