require "test_helper"

class AutomaticMissionEvaluatorTest < ActiveSupport::TestCase
  test "recompensa missão automática de atualização do personagem principal uma vez por período" do
    user = users(:one)
    character = game_characters(:one)
    mission = Mission.create!(
      guild: user.guild,
      name: "Atualizar personagem principal",
      description: "Atualize o personagem principal na semana.",
      mission_type: "automatic",
      frequency: "weekly",
      reward_mode: "fixed",
      reward_xp: 15,
      reward_currency: 5,
      metadata: { "trigger" => "primary_character_updated" }
    )
    original_xp = user.xp_points
    original_currency = user.currency_balance

    assert_difference -> { MissionSubmission.where(mission: mission, user: user).count }, 1 do
      AutomaticMissionEvaluator.evaluate_primary_character_update!(character: character)
    end

    submission = MissionSubmission.find_by!(mission: mission, user: user)
    assert_equal "rewarded", submission.status
    assert_equal 15, submission.reward_xp_awarded
    assert_equal 5, submission.reward_currency_awarded
    assert_equal original_xp + 15, user.reload.xp_points
    assert_equal original_currency + 5, user.currency_balance

    assert_no_difference -> { MissionSubmission.where(mission: mission, user: user).count } do
      AutomaticMissionEvaluator.evaluate_primary_character_update!(character: character)
    end
  end
end
