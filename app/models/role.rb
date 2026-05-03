class Role < ApplicationRecord
  CATEGORY_LABELS = {
    "base" => "Cargo base",
    "cosmetic" => "Cosmético",
    "special" => "Especial",
    "administrative" => "Administrativo",
    "role_maximum" => "Máximo"
  }.freeze

  belongs_to :guild

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :permission_group_roles, dependent: :destroy
  has_many :permission_groups, through: :permission_group_roles

  has_many :role_certificate_requirements, dependent: :destroy
  has_many :required_certificates,
           through: :role_certificate_requirements,
           source: :certificate

  enum :category, {
    base: "base",
    cosmetic: "cosmetic",
    special: "special",
    administrative: "administrative",
    role_maximum: "maximum"
  }, validate: true

  # Ransacker para busca no ActiveAdmin
  ransacker :guild_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel.sql("LOWER(guilds.name)")
  end

  # Permitir busca por estes atributos no ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "discord_role_id", "guild_id", "id",
     "is_admin", "managed_by_app", "name", "updated_at", "guild_name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "users", "user_roles", "required_certificates", "role_certificate_requirements",
      "permission_groups", "permission_group_roles" ]
  end

  validates :name,
            presence: true,
            length: { maximum: 50 }

  def admin?
    is_admin || administrative? || role_maximum?
  end

  def category_label
    CATEGORY_LABELS[category] || category
  end
end
