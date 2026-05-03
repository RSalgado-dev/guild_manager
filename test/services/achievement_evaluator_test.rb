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
end
