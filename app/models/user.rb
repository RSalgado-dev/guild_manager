class User < ApplicationRecord
  belongs_to :guild
  belongs_to :squad, optional: true

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_one :squad_led, class_name: "Squad", foreign_key: "leader_id", dependent: :destroy

  has_many :event_participations, dependent: :destroy
  has_many :events, through: :event_participations

  has_many :mission_submissions, dependent: :destroy
  has_many :missions, through: :mission_submissions

  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements

  has_many :user_certificates, dependent: :destroy
  has_many :certificates, through: :user_certificates

  has_many :currency_transactions, dependent: :destroy

  has_many :audit_logs, dependent: :nullify

  has_many :uploaded_squad_emblems,
           class_name: "Squad",
           foreign_key: :emblem_uploaded_by_id,
           dependent: :nullify

  has_many :reviewed_squad_emblems,
           class_name: "Squad",
           foreign_key: :emblem_reviewed_by_id,
           dependent: :nullify

  validates :discord_id, presence: true, uniqueness: true
  validates :xp_points, numericality: { greater_than_or_equal_to: 0 }
  validates :currency_balance, numericality: { greater_than_or_equal_to: 0 }

  def admin?
    roles.where(is_admin: true).exists?
  end

  def primary_role
    user_roles.primary.includes(:role).first&.role || roles.first
  end

  def grant_achievement(achievement, source: nil)
    UserAchievement.create!(
      user: self,
      achievement:,
      source_type: source&.class&.name,
      source_id: source&.id
    )
  rescue ActiveRecord::RecordNotUnique
    # já possui, ignora silenciosamente
    user_achievements.find_by(achievement: achievement)
  end

  def apply_currency!(delta, reason: nil, description: nil, metadata: {})
    new_balance = currency_balance + delta

    transaction do
      update!(currency_balance: new_balance)

      currency_transactions.create!(
        amount:        delta,
        balance_after: new_balance,
        reason_type:   reason&.class&.name,
        reason_id:     reason&.id,
        description:   description,
        metadata:      metadata
      )
    end
  end
end
