class Role < ApplicationRecord
  belongs_to :guild

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  has_many :role_certificate_requirements, dependent: :destroy
  has_many :required_certificates,
           through: :role_certificate_requirements,
           source: :certificate

  # Ransacker para busca no ActiveAdmin
  ransacker :guild_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel.sql("LOWER(guilds.name)")
  end

  # Permitir busca por estes atributos no ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "color", "created_at", "description", "guild_id", "icon", "id",
     "is_admin", "name", "updated_at", "guild_name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "users", "user_roles", "required_certificates", "role_certificate_requirements" ]
  end

  validates :name,
            presence: true,
            length: { maximum: 50 }

  def admin?
    is_admin
  end
end
