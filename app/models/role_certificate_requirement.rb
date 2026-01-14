class RoleCertificateRequirement < ApplicationRecord
  belongs_to :role
  belongs_to :certificate

  validates :role_id, uniqueness: { scope: :certificate_id }
end
