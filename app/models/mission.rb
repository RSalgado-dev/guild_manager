class Mission < ApplicationRecord
  belongs_to :guild

  has_many :mission_submissions, dependent: :destroy
  has_many :users, through: :mission_submissions

  enum :frequency, {
    # daily:   "daily",
    weekly:  "weekly"
    # monthly: "monthly"
  }, validate: true

  validates :name,
            presence: true

  validates :reward_currency,
            :reward_xp,
            numericality: { greater_than_or_equal_to: 0 }
end
