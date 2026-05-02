class RankingCalculator
  Entry = Struct.new(:rank, :record, :value, keyword_init: true)

  def initialize(ranking)
    @ranking = ranking
    @guild = ranking.guild
  end

  def entries
    ordered_rows.first(ranking.entries_limit).each_with_index.map do |(record, value), index|
      Entry.new(rank: index + 1, record: record, value: value)
    end
  end

  private

  attr_reader :ranking, :guild

  def ordered_rows
    rows = rows_for_metric
    rows.sort_by do |record, value|
      comparable_value = ranking.descending? ? -numeric_value(value) : numeric_value(value)
      [ comparable_value, record_name(record).downcase, record.id ]
    end
  end

  def rows_for_metric
    case ranking.metric
    when "user_level"
      users.map { |user| [ user, user.level ] }
    when "user_xp"
      users.map { |user| [ user, user.xp_points ] }
    when "user_currency_earned"
      users.map { |user| [ user, currency_earned_by_user_id.fetch(user.id, 0) ] }
    when "user_primary_character_power"
      users.map { |user| [ user, primary_character_power_by_user_id.fetch(user.id, 0) ] }
    when "squad_total_xp"
      squads.map { |squad| [ squad, squad.users.sum(&:xp_points) ] }
    when "squad_average_level"
      squads.map { |squad| [ squad, average_level(squad) ] }
    when "squad_members_count"
      squads.map { |squad| [ squad, squad.users.size ] }
    else
      []
    end
  end

  def users
    @users ||= guild.users.with_guild_access.order(:discord_username).to_a
  end

  def squads
    @squads ||= guild.squads.includes(:users).order(:name).to_a
  end

  def currency_earned_by_user_id
    @currency_earned_by_user_id ||= CurrencyTransaction
      .credits
      .joins(:user)
      .where(users: { guild_id: guild.id, has_guild_access: true })
      .group(:user_id)
      .sum(:amount)
  end

  def primary_character_power_by_user_id
    @primary_character_power_by_user_id ||= GameCharacter
      .where(user_id: users.map(&:id), is_primary: true)
      .pluck(:user_id, :power)
      .to_h
  end

  def average_level(squad)
    members = squad.users.to_a
    return 0.0 if members.empty?

    (members.sum(&:level).to_f / members.size).round(1)
  end

  def numeric_value(value)
    value.to_f
  end

  def record_name(record)
    if record.respond_to?(:display_name_with_squad_tag)
      record.display_name_with_squad_tag
    else
      record.name
    end
  end
end
