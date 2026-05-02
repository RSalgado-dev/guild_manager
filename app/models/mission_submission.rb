class MissionSubmission < ApplicationRecord
  belongs_to :mission
  belongs_to :user
  belongs_to :reviewer, class_name: "User", optional: true

  has_one_attached :proof

  validates :week_reference, presence: true
  validates :status, presence: true
  validates :quantity, :period_sequence,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :reward_currency_awarded, :reward_xp_awarded,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :mission_id, uniqueness: { scope: [ :user_id, :week_reference, :period_sequence ] }
  validate :proof_format

  before_validation :set_defaults

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected",
    rewarded: "rewarded"
  }, validate: true

  def week
    week_reference
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "answers_json", "created_at", "id", "mission_id", "period_sequence", "quantity", "review_notes",
      "reviewed_at", "reviewer_id", "reward_currency_awarded", "reward_xp_awarded", "rewarded_at",
      "status", "submitted_at", "updated_at", "user_id", "week_reference" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "mission", "proof_attachment", "proof_blob", "reviewer", "user" ]
  end

  def approve!(reviewer:, notes: nil)
    raise ArgumentError, "Submissão já recompensada." if rewarded?

    reward = mission.reward_for(quantity)

    transaction do
      update!(
        status: "approved",
        reviewer: reviewer,
        reviewed_at: Time.current,
        review_notes: notes,
        reward_xp_awarded: reward[:xp],
        reward_currency_awarded: reward[:currency]
      )

      audit!("mission_submission_approved", actor: reviewer)
    end
  end

  def reject!(reviewer:, notes: nil)
    raise ArgumentError, "Submissão já recompensada." if rewarded?

    transaction do
      update!(
        status: "rejected",
        reviewer: reviewer,
        reviewed_at: Time.current,
        review_notes: notes,
        reward_xp_awarded: 0,
        reward_currency_awarded: 0
      )

      audit!("mission_submission_rejected", actor: reviewer)
    end
  end

  def reward!(reviewer: nil)
    raise ArgumentError, "Submissão já recompensada." if rewarded?
    raise ArgumentError, "Submissão precisa estar aprovada." unless approved?

    transaction do
      user.apply_xp!(reward_xp_awarded) if reward_xp_awarded.positive?

      if reward_currency_awarded.positive?
        user.apply_currency!(
          reward_currency_awarded,
          reason: mission,
          description: "Recompensa da missão #{mission.name}",
          metadata: {
            mission_submission_id: id,
            week_reference: week_reference,
            quantity: quantity
          }
        )
      end

      update!(
        status: "rewarded",
        reviewer: reviewer || self.reviewer,
        rewarded_at: Time.current
      )

      audit!("mission_submission_rewarded", actor: reviewer || self.reviewer)
    end
  end

  def audit!(action, actor:)
    AuditLog.create!(
      user: actor || user,
      guild: mission.guild,
      action: action,
      entity_type: "MissionSubmission",
      entity_id: id,
      metadata: {
        origin: audit_origin(actor),
        result: "success",
        mission_id: mission_id,
        submitted_user_id: user_id,
        status: status,
        week_reference: week_reference,
        period_sequence: period_sequence,
        quantity: quantity,
        reward_xp_awarded: reward_xp_awarded,
        reward_currency_awarded: reward_currency_awarded
      }
    )
  end

  private

  def set_defaults
    self.week_reference = mission.current_period_reference if week_reference.blank? && mission.present?
    self.submitted_at ||= Time.current
  end

  def audit_origin(actor)
    return "app" unless actor
    return "user" if actor == user

    "admin"
  end

  def proof_format
    return unless proof.attached?

    allowed_types = %w[image/jpeg image/jpg image/png image/webp application/pdf text/plain]
    errors.add(:proof, "deve ser imagem, PDF ou texto") unless proof.content_type.in?(allowed_types)
    errors.add(:proof, "deve ter no máximo 10MB") if proof.byte_size > 10.megabytes
  end
end
