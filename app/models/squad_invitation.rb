class SquadInvitation < ApplicationRecord
  INVITATION_TTL = 7.days

  belongs_to :squad
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User"

  enum :status, {
    pending: "pending",
    accepted: "accepted",
    declined: "declined",
    revoked: "revoked",
    expired: "expired"
  }, validate: true

  validates :expires_at, presence: true
  validate :participants_must_belong_to_same_guild
  validate :invitee_must_be_without_squad, on: :create
  validate :inviter_must_be_squad_leader, on: :create

  before_validation :set_default_expiration, on: :create

  scope :pending_open, -> { pending.where("expires_at > ?", Time.current) }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "expires_at", "id", "invitee_id", "inviter_id", "note", "responded_at", "squad_id", "status", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "squad", "inviter", "invitee" ]
  end

  def accept!(user:, accepted_at: Time.current)
    raise ArgumentError, "Convite inválido" unless invitee == user
    raise ArgumentError, "Convite não está pendente" unless pending?
    raise ArgumentError, "Convite expirado" if expires_at <= accepted_at
    raise ArgumentError, "Usuário já possui squad" if invitee.squad_id.present?

    transaction do
      update!(status: "accepted", responded_at: accepted_at)
      invitee.update!(squad: squad)
      self.class.where(invitee: invitee, status: "pending").where.not(id: id).update_all(status: "revoked", responded_at: accepted_at)
    end
  end

  def decline!(user:, declined_at: Time.current)
    raise ArgumentError, "Convite inválido" unless invitee == user
    raise ArgumentError, "Convite não está pendente" unless pending?

    update!(status: "declined", responded_at: declined_at)
  end

  private

  def set_default_expiration
    self.expires_at ||= INVITATION_TTL.from_now
  end

  def participants_must_belong_to_same_guild
    return if squad.blank? || inviter.blank? || invitee.blank?
    return if squad.guild_id == inviter.guild_id && squad.guild_id == invitee.guild_id

    errors.add(:base, "Squad, líder e convidado devem pertencer à mesma guilda")
  end

  def invitee_must_be_without_squad
    return if invitee.blank? || invitee.squad_id.blank?

    errors.add(:invitee, "já pertence a um squad")
  end

  def inviter_must_be_squad_leader
    return if squad.blank? || inviter.blank?
    return if squad.leader_id == inviter.id

    errors.add(:inviter, "deve ser o líder do squad")
  end
end
