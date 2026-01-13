class Guild < ApplicationRecord
  has_many :users,          dependent: :destroy
  has_many :roles,          dependent: :destroy
  has_many :squads,         dependent: :destroy
  has_many :missions,       dependent: :destroy
  has_many :events,         dependent: :destroy

  validates :name,
            presence: true,
            length: { maximum: 100 }
end
