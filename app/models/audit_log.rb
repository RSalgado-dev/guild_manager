class AuditLog < ApplicationRecord
  SENSITIVE_METADATA_KEY_PATTERN = /(token|secret|password|authorization|email)/i
  FILTERED_METADATA_VALUE = "[FILTERED]"

  belongs_to :user, optional: true
  belongs_to :guild, optional: true

  before_validation :sanitize_metadata

  def self.record!(action:, actor: nil, guild: nil, entity: nil, metadata: {})
    create!(
      user: actor,
      guild: guild || infer_guild(entity),
      action: action,
      entity_type: entity&.class&.name,
      entity_id: entity&.id,
      metadata: metadata
    )
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "action", "created_at", "entity_id", "entity_type", "guild_id", "id", "metadata",
      "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "user" ]
  end

  def entity
    return nil if entity_type.blank? || entity_id.blank?

    entity_type.constantize.find_by(id: entity_id)
  rescue NameError
    nil
  end

  # Scopes úteis
  scope :recent, -> { order(created_at: :desc) }
  scope :for_guild, ->(guild_id) { where(guild_id:) }
  scope :by_action, ->(action) { where(action:) }

  def self.infer_guild(entity)
    return nil unless entity
    return entity.guild if entity.respond_to?(:guild)
    return entity.store_item.guild if entity.respond_to?(:store_item) && entity.store_item

    nil
  end
  private_class_method :infer_guild

  def self.sanitize_metadata_value(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, nested_value), sanitized|
        key = key.to_s
        sanitized_value =
          if key.match?(SENSITIVE_METADATA_KEY_PATTERN)
            FILTERED_METADATA_VALUE
          else
            sanitize_metadata_value(nested_value)
          end
        sanitized[key] = sanitized_value
      end
    when Array
      value.map { |nested_value| sanitize_metadata_value(nested_value) }
    else
      value
    end
  end

  def sanitize_metadata
    self.metadata = self.class.sanitize_metadata_value(metadata || {})
  end
end
