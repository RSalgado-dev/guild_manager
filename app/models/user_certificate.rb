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
  after_create :apply_grant_effects!, if: :granted?

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def active_certificate?
    granted? && !expired?
  end

  def revoke!(revoked_by:)
    transaction do
      update!(status: "revoked")
      remove_certificate_role!
      audit_certificate!("certificate_revoked", revoked_by)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "certificate_id", "created_at", "expires_at", "granted_at", "granted_by_id",
      "id", "status", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "certificate", "granted_by", "user" ]
  end

  private

  def set_default_granted_at
    self.granted_at ||= Time.current
  end

  def apply_grant_effects!
    role = certificate.role
    assign_certificate_role!(role) if role

    audit_certificate!("certificate_granted", granted_by)
  end

  def assign_certificate_role!(role)
    user.user_roles.find_or_create_by!(role: role)
    reconcile_certificate_role!(role)
  end

  def remove_certificate_role!
    role = certificate.role
    return unless role
    return if other_active_certificates_grant_role?(role)

    user.user_roles.where(role: role).destroy_all
    reconcile_certificate_role!(role)
  end

  def other_active_certificates_grant_role?(role)
    user.user_certificates
        .joins(:certificate)
        .where(status: "granted")
        .where(certificates: { role_id: role.id })
        .where.not(id: id)
        .any? { |user_certificate| !user_certificate.expired? }
  end

  def reconcile_certificate_role!(role)
    return unless role.managed_by_app?

    DiscordManagedRoleReconciliationJob.perform_later(certificate.guild_id, user_id)
  end

  def audit_certificate!(action, actor)
    AuditLog.create!(
      user: actor || user,
      guild: certificate.guild,
      action: action,
      entity_type: "UserCertificate",
      entity_id: id,
      metadata: {
        origin: actor ? "admin" : "app",
        result: "success",
        certificate_id: certificate_id,
        certified_user_id: user_id,
        role_id: certificate.role_id
      }
    )
  end
end
