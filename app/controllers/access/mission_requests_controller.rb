module Access
  class MissionRequestsController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :ensure_can_request_mission!

    def new
      @mission_request = @guild.mission_requests.new(requester: current_user)
    end

    def create
      @mission_request = @guild.mission_requests.new(mission_request_params.merge(requester: current_user))

      if @mission_request.save
        audit_request_created!
        redirect_to missions_path, notice: "✅ Requisição de missão enviada para a administração."
      else
        flash.now[:alert] = "❌ Não foi possível enviar a requisição: #{@mission_request.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    private

    def mission_request_params
      params.require(:mission_request).permit(:title, :description)
    end

    def ensure_can_request_mission!
      return if current_user.roles.where(guild: @guild, category: "special").exists?
      return if current_user.has_permission?(:manage_missions)

      redirect_to missions_path, alert: "❌ Seu cargo não permite requisitar missões."
    end

    def audit_request_created!
      AuditLog.create!(
        user: current_user,
        guild: @guild,
        action: "mission_request_created",
        entity_type: "MissionRequest",
        entity_id: @mission_request.id,
        metadata: {
          origin: "user",
          result: "success"
        }
      )
    end
  end
end
