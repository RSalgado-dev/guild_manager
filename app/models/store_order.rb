class StoreOrder < ApplicationRecord
  STATUSES = %w[pending fulfilled rejected canceled].freeze

  belongs_to :user
  belongs_to :store_item
  belongs_to :fulfilled_by, class_name: "User", optional: true
  belongs_to :rejected_by, class_name: "User", optional: true
  belongs_to :canceled_by, class_name: "User", optional: true

  enum :status, {
    pending: "pending",
    fulfilled: "fulfilled",
    rejected: "rejected",
    canceled: "canceled"
  }, validate: true

  validates :status, presence: true
  validates :price_paid, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :user_belongs_to_item_guild

  before_validation :set_price_paid, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def self.ransackable_attributes(auth_object = nil)
    [ "admin_notes", "canceled_at", "canceled_by_id", "created_at", "fulfilled_at",
      "fulfilled_by_id", "id", "price_paid", "refunded_at", "rejected_at",
      "rejected_by_id", "status", "store_item_id", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "canceled_by", "fulfilled_by", "rejected_by", "store_item", "user" ]
  end

  def self.checkout!(user:, store_item:)
    transaction do
      store_item.lock!
      user.lock!

      raise ArgumentError, "Item pertence a outra guilda." unless user.guild_id == store_item.guild_id
      raise ArgumentError, "Item indisponível para compra." unless store_item.available_for_purchase?
      raise ArgumentError, "Saldo insuficiente." if user.currency_balance < store_item.price

      order = create!(user: user, store_item: store_item, price_paid: store_item.price)
      store_item.reserve_stock!

      if order.price_paid.positive?
        user.apply_currency!(
          -order.price_paid,
          reason: order,
          description: "Compra na loja: #{store_item.name}",
          metadata: order.currency_metadata.merge("operation" => "checkout")
        )
      end

      order.audit!("store_order_created", actor: user)
      order
    end
  end

  def fulfill!(actor:, notes: nil)
    transaction do
      lock!
      ensure_pending!

      update!(
        status: "fulfilled",
        fulfilled_by: actor,
        fulfilled_at: Time.current,
        admin_notes: notes.presence || admin_notes
      )

      audit!("store_order_fulfilled", actor: actor)
    end
  end

  def reject!(actor:, notes: nil)
    transaction do
      lock!
      ensure_pending!
      store_item.lock!
      user.lock!

      store_item.restore_stock!
      refund_currency!

      update!(
        status: "rejected",
        rejected_by: actor,
        rejected_at: Time.current,
        refunded_at: refunded_at || Time.current,
        admin_notes: notes.presence || admin_notes
      )

      audit!("store_order_rejected", actor: actor)
    end
  end

  def cancel!(actor:)
    transaction do
      lock!
      ensure_pending!
      store_item.lock!
      user.lock!

      store_item.restore_stock!
      refund_currency!

      update!(
        status: "canceled",
        canceled_by: actor,
        canceled_at: Time.current,
        refunded_at: refunded_at || Time.current
      )

      audit!("store_order_canceled", actor: actor)
    end
  end

  def currency_metadata
    {
      "store_order_id" => id,
      "store_item_id" => store_item_id,
      "store_item_name" => store_item.name
    }
  end

  def audit!(action, actor:)
    AuditLog.create!(
      user: actor || user,
      guild: store_item.guild,
      action: action,
      entity_type: "StoreOrder",
      entity_id: id,
      metadata: {
        origin: audit_origin(actor),
        result: "success",
        store_item_id: store_item_id,
        buyer_id: user_id,
        price_paid: price_paid,
        status: status,
        refunded_at: refunded_at
      }
    )
  end

  private

  def set_price_paid
    self.price_paid = store_item.price if price_paid.nil? && store_item.present?
  end

  def ensure_pending!
    raise ArgumentError, "Pedido não está pendente." unless pending?
  end

  def refund_currency!
    return if refunded_at.present?

    if price_paid.positive?
      user.apply_currency!(
        price_paid,
        reason: self,
        description: "Reembolso da loja: #{store_item.name}",
        metadata: currency_metadata.merge("operation" => "refund")
      )
    end

    self.refunded_at = Time.current
  end

  def audit_origin(actor)
    return "app" unless actor
    return "user" if actor == user

    "admin"
  end

  def user_belongs_to_item_guild
    return unless user && store_item
    return if user.guild_id == store_item.guild_id

    errors.add(:user, "deve pertencer à mesma guilda do item")
  end
end
