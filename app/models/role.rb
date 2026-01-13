class Role < ApplicationRecord
  belongs_to :guild

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  has_many :role_certificate_requirements, dependent: :destroy
  has_many :required_certificates, through: :role_certificate_requirements,
                                   source: :certificate

  validates :name,
            presence: true,
            length: { maximum: 50 }

  def admin?
    is_admin
  end
end
