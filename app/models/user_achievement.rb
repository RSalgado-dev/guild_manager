class UserAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :achievement

  validates :user_id, uniqueness: { scope: :achievement_id }
  validate :user_must_belong_to_achievement_guild

  before_validation :set_default_earned_at, on: :create
  after_create :apply_rewards!

  def individual?
    achievement.individual?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "achievement_id", "created_at", "earned_at", "id", "source_id", "source_type", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "achievement", "user" ]
  end

  private

  def set_default_earned_at
    self.earned_at ||= Time.current
  end

  def user_must_belong_to_achievement_guild
    return if user.blank? || achievement.blank?
    return if user.guild_id == achievement.guild_id

    errors.add(:user, "deve pertencer à mesma guilda da conquista")
  end

  def apply_rewards!
    user.apply_xp!(achievement.reward_xp) if achievement.reward_xp.positive?

    if achievement.reward_currency.positive?
      user.apply_currency!(
        achievement.reward_currency,
        reason: achievement,
        description: "Recompensa da conquista #{achievement.name}",
        metadata: {
          user_achievement_id: id,
          achievement_type: achievement.achievement_type
        }
      )
    end

    AuditLog.create!(
      user: user,
      guild: achievement.guild,
      action: "achievement_granted",
      entity_type: "UserAchievement",
      entity_id: id,
      metadata: {
        origin: source_type.present? ? "app" : "admin",
        result: "success",
        achievement_id: achievement_id,
        achievement_type: achievement.achievement_type,
        reward_xp: achievement.reward_xp,
        reward_currency: achievement.reward_currency,
        reward_profile_name_color: achievement.reward_profile_name_color
      }
    )
  end
end
