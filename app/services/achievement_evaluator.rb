class AchievementEvaluator
  SUPPORTED_CRITERIA = %w[
    min_xp
    min_level
    min_currency_balance
    event_participated_count
    mission_rewarded_count
  ].freeze

  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
    @guild = user.guild
  end

  def call
    guild.achievements.active.predefined.find_each.with_object([]) do |achievement, granted|
      next if user.achievements.exists?(achievement.id)
      next unless criteria_met?(achievement.criteria || {})

      granted << user.grant_achievement(achievement, source: self)
    end
  end

  def id
    nil
  end

  private

  attr_reader :user, :guild

  def criteria_met?(criteria)
    return false if criteria.blank?

    criteria.slice(*SUPPORTED_CRITERIA).all? do |key, value|
      criteria_value_met?(key, value.to_i)
    end
  end

  def criteria_value_met?(key, value)
    case key
    when "min_xp"
      user.xp_points >= value
    when "min_level"
      user.level >= value
    when "min_currency_balance"
      user.currency_balance >= value
    when "event_participated_count"
      user.event_participations.participated.count >= value
    when "mission_rewarded_count"
      user.mission_submissions.rewarded.count >= value
    else
      false
    end
  end
end
