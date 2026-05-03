module Access
  class EventsController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :set_event, only: [ :show, :respond, :review, :complete ]
    before_action :require_manage_events_permission, only: [ :new, :create, :review, :complete ]
    before_action :ensure_event_can_be_reviewed!, only: [ :review, :complete ]

    def index
      @upcoming_events = @guild.events.includes(event_participations: :user).upcoming
      @pending_review_events = if has_permission?(:manage_events)
        @guild.events
              .includes(event_participations: :user)
              .where(status: :scheduled)
              .where("starts_at < ?", Time.current)
              .recent_first
      else
        Event.none
      end
      @past_events = @guild.events.includes(event_participations: :user).where.not(status: :scheduled).recent_first.limit(12)
      @my_participations = current_user.event_participations.includes(:event).where(events: { guild_id: @guild.id }).joins(:event)
    end

    def show
      @participation = @event.participation_for(current_user)
    end

    def new
      @event = @guild.events.new(
        starts_at: 1.day.from_now.change(min: 0),
        ends_at: 1.day.from_now.change(min: 0) + 2.hours,
        reward_xp: 100
      )
    end

    def create
      @event = @guild.events.new(event_params.merge(creator: current_user))

      if @event.save
        redirect_to event_path(@event), notice: "✅ Evento criado com sucesso."
      else
        flash.now[:alert] = "❌ Erro ao criar evento: #{@event.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def respond
      @participation = @event.participation_for(current_user)

      unless @event.response_open?
        redirect_to event_path(@event), alert: "❌ O prazo para responder presença terminou."
        return
      end

      if @participation.update(response_params.merge(responded_at: Time.current))
        audit_rsvp_response!(@participation)
        redirect_to event_path(@event), notice: "✅ Sua resposta foi registrada."
      else
        redirect_to event_path(@event), alert: "❌ Não foi possível registrar sua resposta: #{@participation.errors.full_messages.join(', ')}"
      end
    end

    def review
      participation_scope = @event.event_participations.joins(:user).includes(:user).order("users.discord_username ASC")
      @participations = participation_scope
      @confirmed_participations = participation_scope.where(rsvp_status: :confirmed)
      @justified_participations = participation_scope.where(rsvp_status: :declined).where.not(justification: [ nil, "" ])
      @absent_participations = participation_scope.where.not(id: @confirmed_participations.select(:id)).where.not(id: @justified_participations.select(:id))
    end

    def complete
      @event.complete_with_results!(results: completion_params.to_h, actor: current_user)
      redirect_to event_path(@event), notice: "✅ Evento finalizado e recompensas distribuídas."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to review_event_path(@event), alert: "❌ #{e.message}"
    end

    private

    def set_event
      @event = @guild.events.find(params[:id])
    end

    def event_params
      params.require(:event).permit(
        :title,
        :description,
        :event_type,
        :starts_at,
        :ends_at,
        :recurrence,
        :reward_xp,
        :reward_currency
      )
    end

    def response_params
      permitted = params.require(:event_participation).permit(:rsvp_status, :justification)
      permitted[:justification] = nil if permitted[:rsvp_status] == "confirmed"
      if permitted[:rsvp_status] == "declined" && permitted[:justification].to_s.strip.blank?
        @participation.errors.add(:justification, "deve ser informada ao recusar presença")
      end
      permitted
    end

    def completion_params
      raw_results = params[:results]
      return {} unless raw_results.respond_to?(:each_pair)

      raw_results.each_pair.with_object({}) do |(participation_id, status_value), sanitized|
        normalized_status = status_value.to_s
        next unless EventParticipation.final_statuses.key?(normalized_status)

        sanitized[participation_id.to_s] = normalized_status
      end
    end

    def require_manage_events_permission
      return if has_permission?(:manage_events)

      redirect_to events_path, alert: "❌ Você não tem permissão para gerenciar eventos."
    end

    def ensure_event_can_be_reviewed!
      if @event.completed?
        redirect_to event_path(@event), alert: "❌ O evento já foi finalizado."
        return
      end

      return if @event.review_available?

      redirect_to event_path(@event), alert: "❌ O evento ainda não pode ser finalizado."
    end

    def audit_rsvp_response!(participation)
      AuditLog.create!(
        user: current_user,
        guild: @guild,
        action: "event_rsvp_updated",
        entity_type: "EventParticipation",
        entity_id: participation.id,
        metadata: {
          origin: "user",
          result: "success",
          event_id: @event.id,
          rsvp_status: participation.rsvp_status,
          justification_present: participation.justification.present?
        }
      )
    end
  end
end
