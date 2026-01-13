class Role < ApplicationRecord
  belongs_to :guild

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name,
            presence: true,
            length: { maximum: 50 }

  def admin?
    is_admin
  end
end
