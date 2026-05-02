class Ranking < ApplicationRecord
  RANKING_SCOPES = %w[users squads].freeze

  USER_METRICS = {
    "user_level" => "Nível",
    "user_xp" => "XP",
    "user_currency_earned" => "Moedas ganhas",
    "user_primary_character_power" => "Poder do personagem principal"
  }.freeze

  SQUAD_METRICS = {
    "squad_total_xp" => "XP total do squad",
    "squad_average_level" => "Média de nível do squad",
    "squad_members_count" => "Número de membros"
  }.freeze

  METRIC_LABELS = USER_METRICS.merge(SQUAD_METRICS).freeze
  SORT_DIRECTIONS = %w[desc asc].freeze

  belongs_to :guild

  validates :name, presence: true, uniqueness: { scope: :guild_id }
  validates :ranking_scope, inclusion: { in: RANKING_SCOPES }
  validates :metric, inclusion: { in: METRIC_LABELS.keys }
  validates :sort_direction, inclusion: { in: SORT_DIRECTIONS }
  validates :entries_limit, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :metric_matches_scope

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  def entries
    RankingCalculator.new(self).entries
  end

  def metric_label
    METRIC_LABELS[metric] || metric
  end

  def scope_label
    users_scope? ? "Usuários" : "Squads"
  end

  def users_scope?
    ranking_scope == "users"
  end

  def squads_scope?
    ranking_scope == "squads"
  end

  def descending?
    sort_direction == "desc"
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "description", "entries_limit", "guild_id", "id",
      "metric", "name", "position", "ranking_scope", "sort_direction", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "guild" ]
  end

  private

  def metric_matches_scope
    return if ranking_scope.blank? || metric.blank?
    return if users_scope? && USER_METRICS.key?(metric)
    return if squads_scope? && SQUAD_METRICS.key?(metric)

    errors.add(:metric, "não é compatível com o escopo selecionado")
  end
end
