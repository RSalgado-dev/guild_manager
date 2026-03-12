class Squad < ApplicationRecord
  PROFILE_CHANGE_COOLDOWN = 7.days

  belongs_to :guild
  has_many :users, dependent: :nullify
  has_many :squad_invitations, dependent: :destroy

  # Alias para semântica melhor
  alias_method :members, :users

  has_one_attached :emblem
  has_one_attached :emblem_pending

  belongs_to :leader, class_name: "User"
  belongs_to :emblem_uploaded_by, class_name: "User", optional: true
  belongs_to :emblem_reviewed_by, class_name: "User", optional: true
  belongs_to :profile_change_reviewed_by, class_name: "User", optional: true

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
     "max_members", "name", "profile_change_status", "profile_change_requested_at",
     "profile_change_reviewed_at", "profile_change_reviewed_by_id", "tag", "updated_at",
     "guild_name", "leader_discord_username" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "leader", "users", "emblem_uploaded_by", "emblem_reviewed_by",
      "profile_change_reviewed_by", "squad_invitations" ]
  end

  enum :emblem_status, {
    no_emblem: "none",
    pending:   "pending",
    approved:  "approved",
    rejected:  "rejected"
  }, validate: true

  enum :profile_change_status, {
    no_profile_change: "none",
    profile_pending: "pending",
    profile_approved: "approved",
    profile_rejected: "rejected"
  }, validate: true

  validates :name, presence: true
  validates :tag, presence: true, length: { minimum: 2, maximum: 8 }, format: { with: /\A[A-Z0-9]+\z/, message: "deve conter apenas letras e números" }, uniqueness: { scope: :guild_id, case_sensitive: false }

  validate :leader_must_belong_to_guild

  before_validation :normalize_tag

  scope :with_profile_changes_pending, -> { where(profile_change_status: "pending") }

  def profile_change_pending?
    profile_pending?
  end

  def can_request_profile_change?
    return false if profile_change_pending?
    return true if last_profile_change_approved_at.blank?

    last_profile_change_approved_at <= PROFILE_CHANGE_COOLDOWN.ago
  end

  def next_profile_change_available_at
    return Time.current if last_profile_change_approved_at.blank?

    last_profile_change_approved_at + PROFILE_CHANGE_COOLDOWN
  end

  def request_profile_change!(actor:, attributes:, emblem_file: nil)
    raise ArgumentError, "Apenas o líder pode solicitar alteração do squad" unless actor == leader
    raise ArgumentError, "Já existe uma alteração pendente para revisão" if profile_change_pending?
    raise ArgumentError, "Aguarde o período de cooldown para nova alteração" unless can_request_profile_change?

    normalized_attributes = {
      "name" => attributes[:name].to_s.strip,
      "tag" => attributes[:tag].to_s.strip.upcase,
      "description" => attributes[:description].to_s.strip
    }

    normalized_attributes.compact_blank!
    normalized_attributes.select! { |key, value| self[key] != value }

    if normalized_attributes.empty? && emblem_file.blank?
      raise ArgumentError, "Nenhuma alteração foi informada"
    end

    if emblem_file.present?
      emblem_pending.attach(emblem_file)
      self.emblem_uploaded_by = actor
    end

    update!(
      pending_profile_changes: normalized_attributes,
      profile_change_status: "pending",
      profile_change_requested_at: Time.current,
      profile_change_reviewed_at: nil,
      profile_change_reviewed_by: nil,
      profile_change_rejection_reason: nil
    )
  end

  def approve_profile_change!(reviewer:)
    raise ArgumentError, "Sem alteração pendente para aprovação" unless profile_change_pending?

    transaction do
      assign_attributes(pending_profile_changes.slice("name", "tag", "description"))
      save!

      if emblem_pending.attached?
        emblem.attach(emblem_pending.blob)
        emblem_pending.purge
      end

      update!(
        pending_profile_changes: {},
        profile_change_status: "approved",
        profile_change_reviewed_at: Time.current,
        profile_change_reviewed_by: reviewer,
        profile_change_rejection_reason: nil,
        last_profile_change_approved_at: Time.current
      )
    end
  end

  def reject_profile_change!(reviewer:, reason:)
    raise ArgumentError, "Sem alteração pendente para rejeição" unless profile_change_pending?
    raise ArgumentError, "Informe o motivo da rejeição" if reason.to_s.strip.blank?

    emblem_pending.purge if emblem_pending.attached?

    update!(
      pending_profile_changes: {},
      profile_change_status: "rejected",
      profile_change_reviewed_at: Time.current,
      profile_change_reviewed_by: reviewer,
      profile_change_rejection_reason: reason.to_s.strip
    )
  end

  private

  def normalize_tag
    self.tag = tag.to_s.upcase.strip.presence
  end

  def leader_must_belong_to_guild
    return if leader.blank? || guild.blank?
    return if leader.guild_id == guild_id

    errors.add(:leader, "deve pertencer à mesma guilda")
  end
end
