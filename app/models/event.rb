class Event < ApplicationRecord
  belongs_to :guild
  belongs_to :creator, class_name: "User"

  has_many :event_participations, dependent: :destroy
  has_many :users, through: :event_participations

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    canceled:  "canceled"
  }, validate: true

  validates :title, :event_type, :starts_at,
            presence: true

  def finished?
    ends_at.present? && ends_at < Time.current
  end
end
