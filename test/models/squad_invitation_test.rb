require "test_helper"

class SquadInvitationTest < ActiveSupport::TestCase
  test "deve ser válido com dados corretos" do
    invitation = SquadInvitation.new(
      squad: squads(:one),
      inviter: users(:one),
      invitee: users(:five)
    )

    assert invitation.valid?
  end

  test "não deve permitir convidar usuário que já tem squad" do
    invitation = SquadInvitation.new(
      squad: squads(:one),
      inviter: users(:one),
      invitee: users(:two)
    )

    assert_not invitation.valid?
    assert_includes invitation.errors[:invitee], "já pertence a um squad"
  end

  test "aceitar convite adiciona usuário ao squad" do
    invitation = squad_invitations(:one_pending)
    invitee = invitation.invitee

    invitation.accept!(user: invitee)

    assert_equal "accepted", invitation.reload.status
    assert_equal squads(:one).id, invitee.reload.squad_id
  end

  test "recusar convite altera status para declined" do
    invitation = squad_invitations(:one_pending)
    invitation.decline!(user: invitation.invitee)

    assert_equal "declined", invitation.reload.status
  end
end
