class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :guild, optional: true

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
end
