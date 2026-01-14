class Certificate < ApplicationRecord
  belongs_to :guild

  has_many :user_certificates, dependent: :destroy
  has_many :users, through: :user_certificates

  has_many :role_certificate_requirements, dependent: :destroy
  has_many :roles, through: :role_certificate_requirements

  validates :code,
            presence: true

  validates :name,
            presence: true
end
