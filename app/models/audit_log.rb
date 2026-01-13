class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :guild, optional: true

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
end
