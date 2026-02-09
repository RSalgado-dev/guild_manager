class Squad < ApplicationRecord
  belongs_to :guild
  has_many :users, dependent: :nullify

  # Alias para semântica melhor
  alias_method :members, :users

  has_one_attached :emblem
  has_one_attached :emblem_pending

  belongs_to :leader, class_name: "User"
  belongs_to :emblem_uploaded_by, class_name: "User", optional: true
  belongs_to :emblem_reviewed_by, class_name: "User", optional: true

  # Ransackers para busca no ActiveAdmin
  ransacker :guild_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel.sql("LOWER(guilds.name)")
  end

  ransacker :leader_discord_username, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel.sql("LOWER(users.discord_username)")
  end

  # Permitir busca por estes atributos no ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "emblem_reviewed_at", "emblem_reviewed_by_id",
     "emblem_status", "emblem_uploaded_by_id", "guild_id", "id", "leader_id",
     "max_members", "name", "updated_at", "guild_name", "leader_discord_username" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "leader", "users", "emblem_uploaded_by", "emblem_reviewed_by" ]
  end

  enum :emblem_status, {
    no_emblem: "none",
    pending:   "pending",
    approved:  "approved",
    rejected:  "rejected"
  }, validate: true

  validates :name, presence: true
end
