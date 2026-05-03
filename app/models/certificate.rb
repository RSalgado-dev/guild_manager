class Certificate < ApplicationRecord
  belongs_to :guild
  belongs_to :role

  has_many :user_certificates, dependent: :destroy
  has_many :users, through: :user_certificates

  has_many :role_certificate_requirements, dependent: :destroy
  has_many :roles, through: :role_certificate_requirements

  validates :code,
            presence: true

  validates :name,
            presence: true
  validates :role, presence: true

  validates :code,
            uniqueness: { scope: :guild_id }

  validate :role_must_belong_to_guild
  validate :role_must_be_cosmetic

  scope :active, -> { where(active: true) }

  def grants_role?
    role.present?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "category", "code", "created_at", "description", "guild_id", "icon_url",
      "id", "name", "role_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "role", "role_certificate_requirements", "roles", "user_certificates", "users" ]
  end

  private

  def role_must_belong_to_guild
    return if role.blank? || guild.blank? || role.guild_id == guild_id

    errors.add(:role, "deve pertencer à guilda")
  end

  def role_must_be_cosmetic
    return if role.blank? || role.cosmetic?

    errors.add(:role, "deve ser um cargo cosmético")
  end
end
