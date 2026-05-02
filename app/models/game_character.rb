class GameCharacter < ApplicationRecord
  belongs_to :user

  # Imagem do status do personagem
  has_one_attached :status_screenshot

  before_validation :set_primary_for_first_character, on: :create
  before_save :demote_other_primary_characters, if: :becoming_primary?
  before_destroy :store_primary_state_before_destroy
  after_destroy :promote_another_character_if_needed
  after_commit :evaluate_primary_character_update_missions, on: :update

  validates :nickname, presence: true, length: { minimum: 2, maximum: 50 }
  validates :level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 999 }
  validates :power, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :status_screenshot_format
  validate :validate_template_data
  validate :ensure_user_has_a_primary_character

  def self.ransackable_attributes(auth_object = nil)
    [ "character_data", "created_at", "id", "is_primary", "level", "nickname", "power", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user", "status_screenshot_attachment", "status_screenshot_blob" ]
  end

  def template_value_for(key)
    return nickname if key == "nickname"
    return level if key == "level"
    return power if key == "power"

    character_data&.[](key)
  end

  private

  def set_primary_for_first_character
    return unless user.present?
    return if user.game_characters.where(is_primary: true).exists?

    self.is_primary = true
  end

  def becoming_primary?
    will_save_change_to_is_primary? && is_primary?
  end

  def demote_other_primary_characters
    user.game_characters.where.not(id: id).where(is_primary: true).update_all(is_primary: false)
  end

  def store_primary_state_before_destroy
    @was_primary_before_destroy = is_primary?
  end

  def promote_another_character_if_needed
    return unless @was_primary_before_destroy

    replacement = user.game_characters.order(created_at: :asc).first
    replacement&.update_column(:is_primary, true)
  end

  def status_screenshot_format
    return unless status_screenshot.attached?

    unless status_screenshot.content_type.in?(%w[image/jpeg image/jpg image/png image/webp])
      errors.add(:status_screenshot, "deve ser uma imagem (JPEG, PNG ou WEBP)")
    end

    if status_screenshot.byte_size > 5.megabytes
      errors.add(:status_screenshot, "deve ter no máximo 5MB")
    end
  end

  def validate_template_data
    template = user.guild.character_template_fields
    self.character_data = {} unless character_data.is_a?(Hash)

    allowed_custom_keys = template.reject { |field| field["system"] }.map { |field| field["key"] }
    unknown_keys = character_data.keys.map(&:to_s) - allowed_custom_keys
    if unknown_keys.any?
      errors.add(:character_data, "possui campos não permitidos: #{unknown_keys.join(', ')}")
    end

    template.each do |field|
      key = field["key"]
      value = template_value_for(key)

      if field["required"] && blank_value?(value)
        errors.add(:base, "#{field['label']} é obrigatório")
        next
      end

      next if blank_value?(value)

      case field["field_type"]
      when "integer"
        errors.add(:base, "#{field['label']} deve ser inteiro") unless integer_like?(value)
      when "decimal"
        errors.add(:base, "#{field['label']} deve ser numérico") unless decimal_like?(value)
      when "boolean"
        errors.add(:base, "#{field['label']} deve ser verdadeiro ou falso") unless boolean_like?(value)
      end
    end
  end

  def ensure_user_has_a_primary_character
    return unless user.present?
    return if is_primary?

    has_other_primary = user.game_characters.where(is_primary: true).where.not(id: id).exists?
    errors.add(:is_primary, "deve ter um personagem principal") unless has_other_primary
  end

  def blank_value?(value)
    value.respond_to?(:blank?) ? value.blank? : value.nil?
  end

  def integer_like?(value)
    return true if value.is_a?(Integer)

    Integer(value)
    true
  rescue ArgumentError, TypeError
    false
  end

  def decimal_like?(value)
    return true if value.is_a?(Numeric)

    Float(value)
    true
  rescue ArgumentError, TypeError
    false
  end

  def boolean_like?(value)
    return true if value == true || value == false

    %w[true false 1 0].include?(value.to_s.downcase)
  end

  def evaluate_primary_character_update_missions
    return unless is_primary?
    return if (previous_changes.keys & %w[nickname level power character_data]).empty?

    AutomaticMissionEvaluator.evaluate_primary_character_update!(character: self)
  end
end
