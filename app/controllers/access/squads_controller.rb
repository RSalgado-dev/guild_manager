module Access
  class SquadsController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :set_squad, only: [ :show, :request_profile_change, :approve_profile_change, :reject_profile_change, :create_invitation ]
    before_action :require_manage_members_permission, only: [ :new, :create, :pending_reviews, :approve_profile_change, :reject_profile_change ]
    before_action :require_squad_leader!, only: [ :request_profile_change, :create_invitation ]

    def index
      @squads = @guild.squads.includes(:leader, emblem_attachment: :blob).order(:name)
      @pending_invitations = current_user.received_squad_invitations.pending_open.includes(:squad, :inviter)
    end

    def show
      @members = @squad.members.order(:discord_username)
      @pending_invitations = @squad.squad_invitations.pending_open.includes(:invitee) if @squad.leader_id == current_user.id
      @eligible_members_for_invite = @guild.users.where(squad_id: nil).where.not(id: @squad.members.select(:id)).order(:discord_username) if @squad.leader_id == current_user.id
    end

    def new
      @squad = @guild.squads.new
      @leader_candidates = @guild.users.where(squad_id: nil).order(:discord_username)
    end

    def create
      @squad = @guild.squads.new(squad_create_params.except(:leader_id))
      @squad.leader = selected_leader_candidate
      @leader_candidates = @guild.users.where(squad_id: nil).order(:discord_username)

      if @squad.save
        @squad.leader.update!(squad: @squad)
        redirect_to squad_path(@squad), notice: "✅ Squad criado com sucesso."
      else
        flash.now[:alert] = "❌ Erro ao criar squad: #{@squad.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def pending_reviews
      @pending_squads = @guild.squads.with_profile_changes_pending.includes(:leader, emblem_attachment: :blob, emblem_pending_attachment: :blob)
    end

    def request_profile_change
      begin
        @squad.request_profile_change!(
          actor: current_user,
          attributes: squad_profile_change_params,
          emblem_file: params.dig(:squad, :emblem_pending)
        )
        redirect_to squad_path(@squad), notice: "✅ Alteração enviada para revisão."
      rescue ArgumentError, ActiveRecord::RecordInvalid => e
        redirect_to squad_path(@squad), alert: "❌ #{e.message}"
      end
    end

    def approve_profile_change
      @squad.approve_profile_change!(reviewer: current_user)
      redirect_to pending_reviews_squads_path, notice: "✅ Alteração aprovada."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to pending_reviews_squads_path, alert: "❌ #{e.message}"
    end

    def reject_profile_change
      @squad.reject_profile_change!(reviewer: current_user, reason: params[:reason])
      redirect_to pending_reviews_squads_path, notice: "✅ Alteração rejeitada."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to pending_reviews_squads_path, alert: "❌ #{e.message}"
    end

    def create_invitation
      invitee = @guild.users.find_by(id: params[:invitee_id])
      invitation = @squad.squad_invitations.new(inviter: current_user, invitee: invitee, note: params[:note])

      if invitation.save
        redirect_to squad_path(@squad), notice: "✅ Convite enviado para #{invitee.discord_username}."
      else
        redirect_to squad_path(@squad), alert: "❌ Não foi possível enviar convite: #{invitation.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_squad
      @squad = @guild.squads.find(params[:id])
    end

    def squad_create_params
      params.require(:squad).permit(:name, :tag, :description, :leader_id)
    end

    def selected_leader_candidate
      @guild.users.where(squad_id: nil).find_by(id: params.dig(:squad, :leader_id))
    end

    def squad_profile_change_params
      params.require(:squad).permit(:name, :tag, :description)
    end

    def require_manage_members_permission
      return if has_permission?(:manage_members)

      redirect_to dashboard_path, alert: "❌ Você não tem permissão para gerenciar membros."
    end

    def require_squad_leader!
      return if @squad.leader_id == current_user.id

      redirect_to squad_path(@squad), alert: "❌ Apenas o líder do squad pode executar esta ação."
    end
  end
end
