class MissionSubmission < ApplicationRecord
  belongs_to :mission
  belongs_to :user

  validates :week_reference, presence: true

  validates :mission_id, uniqueness: { scope: [ :user_id, :week_reference ] }

  def week
    week_reference
  end
end
