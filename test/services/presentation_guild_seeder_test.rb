# frozen_string_literal: true

require "test_helper"

class PresentationGuildSeederTest < ActiveSupport::TestCase
  test "creates a complete presentation guild with varied records" do
    summary = PresentationGuildSeeder.call(
      user_count: 12,
      reset: true,
      reference_time: Time.zone.local(2026, 5, 5, 12, 0, 0)
    )

    guild = Guild.find_by!(discord_guild_id: PresentationGuildSeeder::GUILD_DISCORD_ID)

    assert_equal 12, summary[:users]
    assert_equal 12, guild.users.count
    assert guild.roles.where(category: "maximum").exists?
    assert_operator guild.permission_groups.count, :>=, 5
    assert_operator guild.squads.count, :>=, 3
    assert_operator guild.events.completed.count, :>=, 8
    assert_operator guild.missions.manual.count, :>=, 4
    assert_operator guild.missions.automatic.count, :>=, 4
    assert_operator summary[:mission_submissions], :positive?
    assert_operator summary[:store_orders], :positive?
    assert_operator summary[:user_certificates], :positive?
    assert_operator summary[:audit_logs], :positive?
    assert_equal Ranking::METRIC_LABELS.keys.sort, guild.rankings.pluck(:metric).sort
  end
end
