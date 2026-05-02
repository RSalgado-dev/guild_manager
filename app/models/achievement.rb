class Achievement < ApplicationRecord
  attr_writer :criteria_json

  belongs_to :guild

  has_many :user_achievements, dependent: :destroy
  has_many :users, through: :user_achievements

  enum :achievement_type, {
    predefined: "predefined",
    individual: "individual"
  }, validate: true

  enum :visibility, {
    catalog: "catalog",
    profile_only: "profile_only"
  }, validate: true

  validates :code,
            presence: true,
            uniqueness: { scope: :guild_id }

  validates :name,
            presence: true

  validates :reward_xp, :reward_currency,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :reward_profile_name_color,
            format: { with: /\A#[0-9A-Fa-f]{6}\z/, allow_blank: true }

  before_validation :parse_criteria_json

  validate :criteria_must_be_hash
  validate :individual_achievements_cannot_unlock_customization

  scope :active, -> { where(active: true) }
  scope :catalog_visible, -> { active.predefined.catalog.order(:category, :name) }

  def grants_customization?
    predefined? && reward_profile_name_color.present?
  end

  def criteria_json
    @criteria_json || JSON.pretty_generate(criteria || {})
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "achievement_type", "active", "category", "code", "created_at", "criteria", "description",
      "guild_id", "icon_url", "id", "name", "reward_currency", "reward_profile_name_color",
      "reward_xp", "updated_at", "visibility" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "user_achievements", "users" ]
  end

  private

  def parse_criteria_json
    return if @criteria_json.blank?

    self.criteria = JSON.parse(@criteria_json)
  rescue JSON::ParserError
    errors.add(:criteria, "deve estar em JSON válido")
  end

  def criteria_must_be_hash
    return if criteria.is_a?(Hash)

    errors.add(:criteria, "deve ser um objeto")
  end

  def individual_achievements_cannot_unlock_customization
    return unless individual? && reward_profile_name_color.present?

    errors.add(:reward_profile_name_color, "não pode ser definido para conquistas individuais")
  end
end
