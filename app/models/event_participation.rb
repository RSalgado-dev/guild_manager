class EventParticipation < ApplicationRecord
  REWARD_RULES = {
    confirmed: {
      "participated" => 1.0,
      "justified" => 0.0,
      "absent" => 0.0
    },
    justified: {
      "participated" => 0.5,
      "justified" => 0.2,
      "absent" => 0.0
    },
    absent: {
      "participated" => 0.25,
      "justified" => 0.0,
      "absent" => 0.0
    }
  }.freeze

  belongs_to :event
  belongs_to :user

  enum :rsvp_status, {
    pending: "pending",
    confirmed: "confirmed",
    declined: "declined"
  }, validate: true

  enum :final_status, {
    participated: "participated",
    justified: "justified",
    absent: "absent"
  }, validate: { allow_nil: true }

  validates :event_id, uniqueness: { scope: :user_id }
  validates :reward_xp_awarded, :reward_currency_awarded,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :justification_required_when_declined

  scope :attended, -> { where(attended: true) }
  scope :participated, -> { where(final_status: :participated) }
  scope :justified, -> { where(final_status: :justified) }
  scope :absent, -> { where(final_status: :absent) }

  def source_block
    return :confirmed if confirmed?
    return :justified if declined? && justification.present?

    :absent
  end

  def default_final_status
    case source_block
    when :confirmed
      "participated"
    when :justified
      "justified"
    else
      "absent"
    end
  end

  def reward_multiplier_for(status_value)
    REWARD_RULES.fetch(source_block).fetch(status_value.to_s, 0.0)
  end

  def awarded_xp_for(status_value)
    (event.reward_xp * reward_multiplier_for(status_value)).round
  end

  def awarded_currency_for(status_value)
    (event.reward_currency * reward_multiplier_for(status_value)).round
  end

  def apply_review_result!(status_value, actor: nil)
    raise ArgumentError, "Participação já recompensada." if rewarded_at.present?

    awarded_xp = awarded_xp_for(status_value)
    awarded_currency = awarded_currency_for(status_value)
    multiplier = reward_multiplier_for(status_value)

    transaction do
      update!(
        final_status: status_value,
        attended: status_value.to_s == "participated",
        reward_xp_awarded: awarded_xp,
        reward_currency_awarded: awarded_currency,
        rewarded_at: Time.current
      )

      user.apply_xp!(awarded_xp) if awarded_xp.positive?

      if awarded_currency.positive?
        user.apply_currency!(
          awarded_currency,
          reason: event,
          description: "Recompensa do evento #{event.title}",
          metadata: {
            participation_id: id,
            source_block: source_block,
            final_status: status_value,
            reward_multiplier: multiplier
          }
        )
      end

      audit_reward!(status_value, awarded_xp, awarded_currency, multiplier, actor)
      AutomaticMissionEvaluator.evaluate_event_attended_count!(participation: self) if participated?
    end
  end

  private

  def audit_reward!(status_value, awarded_xp, awarded_currency, multiplier, actor)
    AuditLog.create!(
      user: actor || user,
      guild: event.guild,
      action: "event_reward_awarded",
      entity_type: "EventParticipation",
      entity_id: id,
      metadata: {
        origin: "admin",
        result: "success",
        event_id: event_id,
        rewarded_user_id: user_id,
        source_block: source_block,
        rsvp_status: rsvp_status,
        final_status: status_value.to_s,
        reward_multiplier: multiplier,
        reward_xp_awarded: awarded_xp,
        reward_currency_awarded: awarded_currency
      }
    )
  end

  def justification_required_when_declined
    return unless declined?
    return if justification.to_s.strip.present?

    errors.add(:justification, "deve ser informada ao recusar presença")
  end
end
