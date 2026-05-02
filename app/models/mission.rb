class Mission < ApplicationRecord
  attr_writer :metadata_json

  belongs_to :guild

  has_many :mission_submissions, dependent: :destroy
  has_many :users, through: :mission_submissions

  enum :mission_type, {
    manual: "manual",
    automatic: "automatic"
  }, validate: true

  enum :frequency, {
    daily: "daily",
    weekly: "weekly",
    monthly: "monthly"
  }, validate: true

  enum :reward_mode, {
    fixed: "fixed",
    per_unit: "per_unit"
  }, validate: true

  validates :name,
            presence: true

  validates :reward_currency,
            :reward_xp,
            numericality: { greater_than_or_equal_to: 0 }

  validates :reward_currency_per_unit,
            :reward_xp_per_unit,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :max_submissions_per_period,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  before_validation :parse_metadata_json

  validate :metadata_must_be_hash

  scope :active, -> { where(active: true) }

  def current_period_reference(reference_time: Time.current)
    case frequency
    when "daily"
      reference_time.to_date.iso8601
    when "monthly"
      reference_time.strftime("%Y-%m")
    else
      year, week = reference_time.to_date.cweek.then { |week_number| [ reference_time.to_date.cwyear, week_number ] }
      format("%<year>d-W%<week>02d", year: year, week: week)
    end
  end

  def reward_for(quantity)
    normalized_quantity = [ quantity.to_i, 1 ].max

    if per_unit?
      {
        xp: reward_xp_per_unit * normalized_quantity,
        currency: reward_currency_per_unit * normalized_quantity
      }
    else
      {
        xp: reward_xp,
        currency: reward_currency
      }
    end
  end

  def submissions_count_for(user, period_reference)
    mission_submissions.where(user:, week_reference: period_reference).count
  end

  def accepts_submission_from?(user, period_reference = current_period_reference)
    active? && manual? && submissions_count_for(user, period_reference) < max_submissions_per_period
  end

  def next_period_sequence_for(user, period_reference)
    used_sequences = mission_submissions.where(user:, week_reference: period_reference).pluck(:period_sequence)
    (1..max_submissions_per_period).find { |sequence| used_sequences.exclude?(sequence) }
  end

  def metadata_json
    @metadata_json || JSON.pretty_generate(metadata || {})
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "description", "frequency", "guild_id", "id", "max_submissions_per_period",
      "metadata", "mission_type", "name", "reward_currency", "reward_currency_per_unit", "reward_mode",
      "reward_xp", "reward_xp_per_unit", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild", "mission_submissions", "users" ]
  end

  private

  def parse_metadata_json
    return if @metadata_json.blank?

    self.metadata = JSON.parse(@metadata_json)
  rescue JSON::ParserError
    errors.add(:metadata, "deve estar em JSON válido")
  end

  def metadata_must_be_hash
    return if metadata.is_a?(Hash)

    errors.add(:metadata, "deve ser um objeto")
  end
end
