module Access
  class MissionsController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :set_mission, only: [ :show, :submit ]

    def index
      @missions = @guild.missions.active.order(:name)
      @my_submissions = current_user.mission_submissions.includes(:mission).where(missions: { guild_id: @guild.id }).joins(:mission).order(created_at: :desc)
      @can_request_mission = can_request_mission?
    end

    def show
      @period_reference = @mission.current_period_reference
      @period_submissions = current_user.mission_submissions.where(mission: @mission, week_reference: @period_reference).order(:period_sequence)
      @submission = current_user.mission_submissions.build(mission: @mission, week_reference: @period_reference, quantity: 1)
    end

    def submit
      @period_reference = @mission.current_period_reference
      unless @mission.accepts_submission_from?(current_user, @period_reference)
        redirect_to mission_path(@mission), alert: "❌ Limite de submissões atingido para este período."
        return
      end

      @submission = current_user.mission_submissions.build(submission_attributes)

      if @submission.save
        @submission.audit!("mission_submission_created", actor: current_user)
        redirect_to mission_path(@mission), notice: "✅ Submissão enviada para revisão."
      else
        @period_submissions = current_user.mission_submissions.where(mission: @mission, week_reference: @period_reference).order(:period_sequence)
        flash.now[:alert] = "❌ Não foi possível enviar a submissão: #{@submission.errors.full_messages.join(', ')}"
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_mission
      @mission = @guild.missions.active.find(params[:id])
    end

    def submission_attributes
      permitted = params.require(:mission_submission).permit(:quantity, :proof, :notes)
      {
        mission: @mission,
        week_reference: @period_reference,
        period_sequence: @mission.next_period_sequence_for(current_user, @period_reference),
        quantity: permitted[:quantity],
        answers_json: { "notes" => permitted[:notes].to_s.strip }.compact_blank,
        proof: permitted[:proof]
      }
    end

    def can_request_mission?
      current_user.roles.where(guild: @guild, category: "special").exists? || current_user.has_permission?(:manage_missions)
    end
  end
end
