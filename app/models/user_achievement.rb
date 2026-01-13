class UserAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :achievement

  validates :user_id, uniqueness: { scope: :achievement_id }

  before_validation :set_default_earned_at, on: :create

  private

  def set_default_earned_at
    self.earned_at ||= Time.current
  end
end
