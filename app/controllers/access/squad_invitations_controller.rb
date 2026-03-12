module Access
  class SquadInvitationsController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :set_invitation, only: [ :accept, :decline ]

    def accept
      @invitation.accept!(user: current_user)
      redirect_to squad_path(@invitation.squad), notice: "✅ Convite aceito. Você entrou no squad."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to squads_path, alert: "❌ #{e.message}"
    end

    def decline
      @invitation.decline!(user: current_user)
      redirect_to squads_path, notice: "✅ Convite recusado."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to squads_path, alert: "❌ #{e.message}"
    end

    private

    def set_invitation
      @invitation = current_user.received_squad_invitations.find(params[:id])
    end
  end
end
