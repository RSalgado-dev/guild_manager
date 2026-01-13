class EventParticipation < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :event_id, uniqueness: { scope: :user_id }
  validates :rsvp_status, inclusion: { in: %w[ yes maybe no ], allow_blank: true }

  scope :attended, -> { where(attended: true) }
end
