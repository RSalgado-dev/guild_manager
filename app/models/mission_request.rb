class MissionRequest < ApplicationRecord
  belongs_to :guild
  belongs_to :requester, class_name: "User"
  belongs_to :reviewer, class_name: "User", optional: true

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }, validate: true

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, presence: true
  validate :requester_belongs_to_guild
  validate :reviewer_belongs_to_guild

  scope :recent_first, -> { order(created_at: :desc) }

  def self.ransackable_attributes(auth_object = nil)
    [ "admin_notes", "created_at", "description", "guild_id", "id", "metadata", "requester_id",
      "reviewed_at", "reviewer_id", "status", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "requester", "reviewer" ]
  end

  def approve!(reviewer:, notes: nil)
    review!("approved", reviewer:, notes:)
  end

  def reject!(reviewer:, notes: nil)
    review!("rejected", reviewer:, notes:)
  end

  def requester_can_create?
    requester.roles.where(guild:, category: "special").exists? || requester.has_permission?(:manage_missions)
  end

  private

  def review!(status_value, reviewer:, notes:)
    update!(
      status: status_value,
      reviewer: reviewer,
      reviewed_at: Time.current,
      admin_notes: notes
    )

    AuditLog.create!(
      user: reviewer,
      guild: guild,
      action: "mission_request_#{status_value}",
      entity_type: "MissionRequest",
      entity_id: id,
      metadata: {
        origin: "admin",
        result: "success",
        requester_id: requester_id
      }
    )
  end

  def requester_belongs_to_guild
    return if requester.blank? || guild.blank? || requester.guild_id == guild_id

    errors.add(:requester, "deve pertencer à guilda")
  end

  def reviewer_belongs_to_guild
    return if reviewer.blank? || guild.blank? || reviewer.guild_id == guild_id

    errors.add(:reviewer, "deve pertencer à guilda")
  end
end
