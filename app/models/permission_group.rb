class PermissionGroup < ApplicationRecord
  AVAILABLE_PERMISSIONS = %w[
    manage_guild_settings
    manage_roles
    manage_administrative_roles
    manage_members
    manage_events
    manage_missions
    review_mission_submissions
    manage_achievements
    grant_achievements
    manage_certificates
    grant_certificates
    manage_rankings
    manage_store
    fulfill_store_orders
    view_audit_logs
  ].freeze

  PERMISSION_LABELS = {
    "manage_guild_settings" => "Gerenciar configurações da guilda",
    "manage_roles" => "Gerenciar cargos",
    "manage_administrative_roles" => "Gerenciar cargos administrativos",
    "manage_members" => "Gerenciar membros",
    "manage_events" => "Gerenciar eventos",
    "manage_missions" => "Gerenciar missões",
    "review_mission_submissions" => "Revisar submissões de missão",
    "manage_achievements" => "Gerenciar conquistas",
    "grant_achievements" => "Conceder conquistas",
    "manage_certificates" => "Gerenciar certificados",
    "grant_certificates" => "Conceder certificados",
    "manage_rankings" => "Gerenciar rankings",
    "manage_store" => "Gerenciar loja",
    "fulfill_store_orders" => "Atender pedidos da loja",
    "view_audit_logs" => "Ver auditoria"
  }.freeze

  belongs_to :guild

  has_many :permission_group_roles, dependent: :destroy
  has_many :roles, through: :permission_group_roles

  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :guild_id }
  validates :permissions, presence: true
  validate :permissions_must_be_allowed
  validate :must_have_roles_unless_full_access

  before_validation :normalize_permissions

  def self.ransackable_attributes(auth_object = nil)
    [ "all_access", "created_at", "description", "guild_id", "id", "name", "permissions", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "roles", "permission_group_roles" ]
  end

  def full_access?
    all_access
  end

  def permission_enabled?(permission_key)
    full_access? || permissions.include?(permission_key.to_s)
  end

  private

  def normalize_permissions
    self.permissions = Array(permissions).map(&:to_s).reject(&:blank?).uniq
    self.permissions = AVAILABLE_PERMISSIONS if all_access?
  end

  def permissions_must_be_allowed
    invalid_permissions = permissions - AVAILABLE_PERMISSIONS
    return if invalid_permissions.empty?

    errors.add(:permissions, "contém permissões inválidas: #{invalid_permissions.join(', ')}")
  end

  def must_have_roles_unless_full_access
    return if full_access?
    return if roles.any? || permission_group_roles.any?

    errors.add(:roles, "deve ter ao menos uma role do Discord vinculada")
  end
end
