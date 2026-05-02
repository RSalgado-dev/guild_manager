class StoreItem < ApplicationRecord
  STATUSES = %w[active inactive archived].freeze
  FULFILLMENT_TYPES = %w[manual].freeze

  belongs_to :guild
  has_many :store_orders, dependent: :restrict_with_exception

  enum :status, {
    active: "active",
    inactive: "inactive",
    archived: "archived"
  }, validate: true

  enum :fulfillment_type, {
    manual: "manual"
  }, validate: true

  validates :name, presence: true, length: { maximum: 120 }
  validates :status, :fulfillment_type, presence: true
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :stock_quantity,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  before_validation :normalize_category

  scope :available, -> { active.where("stock_quantity IS NULL OR stock_quantity > 0") }
  scope :ordered, -> { order(Arel.sql("LOWER(COALESCE(category, '')) ASC"), Arel.sql("LOWER(name) ASC")) }

  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "fulfillment_type", "guild_id", "id",
      "name", "price", "status", "stock_quantity", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "store_orders" ]
  end

  def unlimited_stock?
    stock_quantity.nil?
  end

  def in_stock?
    unlimited_stock? || stock_quantity.positive?
  end

  def available_for_purchase?
    active? && in_stock?
  end

  def category_label
    category.presence || "Geral"
  end

  def reserve_stock!
    raise ArgumentError, "Item sem estoque." unless in_stock?
    return true if unlimited_stock?

    update!(stock_quantity: stock_quantity - 1)
  end

  def restore_stock!
    return true if unlimited_stock?

    update!(stock_quantity: stock_quantity + 1)
  end

  private

  def normalize_category
    self.category = category.to_s.strip.presence
  end
end
