class Achievement < ApplicationRecord
  belongs_to :guild

  has_many :user_achievements, dependent: :destroy
  has_many :users, through: :user_achievements

  validates :code,
            presence: true,
            uniqueness: { scope: :guild_id }

  validates :name,
            presence: true
end
