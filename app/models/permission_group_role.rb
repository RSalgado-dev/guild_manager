class PermissionGroupRole < ApplicationRecord
  belongs_to :permission_group
  belongs_to :role

  validates :role_id, uniqueness: { scope: :permission_group_id }

  validate :same_guild

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "permission_group_id", "role_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "permission_group", "role" ]
  end

  private

  def same_guild
    return if permission_group.blank? || role.blank?
    return if permission_group.guild_id == role.guild_id

    errors.add(:role, "deve pertencer à mesma guilda do grupo de permissões")
  end
end
