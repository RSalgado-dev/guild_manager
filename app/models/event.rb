class Event < ApplicationRecord
  belongs_to :guild
  belongs_to :creator, class_name: "User"

  has_many :event_participations, dependent: :destroy
  has_many :users, through: :event_participations

  enum :recurrence, {
    unique: "unique",
    daily: "daily",
    weekly: "weekly",
    monthly: "monthly"
  }, validate: true

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    canceled:  "canceled"
  }, validate: true

  validates :title, :event_type, :starts_at, :recurrence,
            presence: true
  validates :reward_xp, :reward_currency,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :ends_at_after_starts_at

  scope :upcoming, -> { where(status: :scheduled).where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :recent_first, -> { order(starts_at: :desc) }

  after_create :create_initial_participations!
  after_create :audit_created!

  def finished?
    ends_at.present? && ends_at < Time.current
  end

  def response_deadline
    starts_at - 15.minutes
  end

  def response_open?
    response_open_at?(Time.current)
  end

  def response_open_at?(reference_time)
    scheduled? && reference_time <= response_deadline
  end

  def participation_for(user)
    event_participations.find_or_create_by!(user: user)
  end

  def create_initial_participations!
    guild.users.find_each do |user|
      event_participations.find_or_create_by!(user: user)
    end
  end

  def review_available?
    scheduled? && starts_at <= Time.current
  end

  def complete_with_results!(results:, actor: nil)
    transaction do
      raise ArgumentError, "Evento já foi finalizado." if completed?

      event_participations.includes(:user).find_each do |participation|
        final_status = results[participation.id.to_s] || results[participation.id] || participation.default_final_status

        participation.apply_review_result!(final_status, actor: actor)
      end

      update!(status: :completed)
      audit_completed!(actor)
    end
  end

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "deve ser maior do que o horário de início")
  end

  def audit_created!
    AuditLog.create!(
      user: creator,
      guild: guild,
      action: "event_created",
      entity_type: "Event",
      entity_id: id,
      metadata: {
        origin: "admin",
        result: "success",
        event_type: event_type,
        starts_at: starts_at,
        ends_at: ends_at,
        recurrence: recurrence,
        reward_xp: reward_xp,
        reward_currency: reward_currency
      }
    )
  end

  def audit_completed!(actor)
    AuditLog.create!(
      user: actor,
      guild: guild,
      action: "event_completed",
      entity_type: "Event",
      entity_id: id,
      metadata: {
        origin: "admin",
        result: "success",
        participation_count: event_participations.count,
        reward_xp_total: event_participations.sum(:reward_xp_awarded),
        reward_currency_total: event_participations.sum(:reward_currency_awarded)
      }
    )
  end
end
