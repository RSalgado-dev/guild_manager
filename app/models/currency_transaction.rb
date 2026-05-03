class CurrencyTransaction < ApplicationRecord
  ALLOWED_REASON_TYPES = %w[
    Achievement
    Event
    Mission
    StoreOrder
  ].freeze

  belongs_to :user

  validates :amount,
            presence: true,
            numericality: { only_integer: true, other_than: 0 }

  validates :balance_after,
            presence: true,
            numericality: { only_integer: true }

  # Créditos (ganho de moeda) e débitos (gasto)
  scope :credits, -> { where("amount > 0") }
  scope :debits,  -> { where("amount < 0") }

  # Acessar a "origem" (Event, Mission, etc.) se estiver preenchida
  def reason
    return nil if reason_type.blank? || reason_id.blank?
    return nil unless ALLOWED_REASON_TYPES.include?(reason_type)

    reason_type.constantize.find_by(id: reason_id)
  rescue NameError
    nil
  end
end
