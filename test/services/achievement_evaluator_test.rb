require "test_helper"

class AchievementEvaluatorTest < ActiveSupport::TestCase
  test "concede conquista quando critérios JSON são atendidos" do
    user = users(:five)
    user.update!(xp_points: 120)
    achievement = Achievement.create!(
      guild: user.guild,
      code: "xp_120",
      name: "XP 120",
      criteria: { "min_xp" => 120 }
    )

    assert_difference -> { UserAchievement.where(user: user, achievement: achievement).count }, 1 do
      AchievementEvaluator.call(user)
    end
  end

  test "ignora conquistas sem critérios" do
    user = users(:five)
    achievement = achievements(:one)

    assert_no_difference -> { UserAchievement.where(user: user, achievement: achievement).count } do
      AchievementEvaluator.call(user)
    end
  end

  test "concede conquistas por critérios gamificados suportados" do
    user = users(:five)
    user.update!(
      xp_points: User.total_xp_for_level(2),
      currency_balance: 75
    )
    event = Event.create!(
      guild: user.guild,
      creator: users(:one),
      title: "Evento para conquista",
      event_type: "raid",
      starts_at: 2.days.ago,
      ends_at: 2.days.ago + 1.hour,
      status: "completed"
    )
    event.event_participations.find_by!(user: user).update!(final_status: "participated")
    MissionSubmission.create!(
      mission: missions(:one),
      user: user,
      week_reference: "2026-W50",
      period_sequence: 1,
      status: "rewarded",
      rewarded_at: Time.current
    )
    achievements = {
      "level_two" => { "min_level" => 2 },
      "currency_75" => { "min_currency_balance" => 75 },
      "event_participated_once" => { "event_participated_count" => 1 },
      "mission_rewarded_once" => { "mission_rewarded_count" => 1 }
    }.map do |code, criteria|
      Achievement.create!(
        guild: user.guild,
        code: code,
        name: code.humanize,
        criteria: criteria
      )
    end

    assert_difference -> { UserAchievement.where(user: user, achievement: achievements).count }, achievements.size do
      AchievementEvaluator.call(user)
    end
  end

  test "não concede conquista com critério desconhecido" do
    user = users(:five)
    achievement = Achievement.create!(
      guild: user.guild,
      code: "unknown_criteria",
      name: "Critério desconhecido",
      criteria: { "unknown" => 1 }
    )

    assert_no_difference -> { UserAchievement.where(user: user, achievement: achievement).count } do
      AchievementEvaluator.call(user)
    end
  end
end
