class UserCertificate < ApplicationRecord
  belongs_to :user
  belongs_to :certificate
  belongs_to :granted_by, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :certificate_id }

  enum :status, {
    granted: "granted",
    revoked: "revoked"
  }, validate: true

  before_validation :set_default_granted_at, on: :create

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  private

  def set_default_granted_at
    self.granted_at ||= Time.current
  end
end
