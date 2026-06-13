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

  test "não recompensa atualização de personagem secundário" do
    user = users(:one)
    secondary = user.game_characters.create!(
      nickname: "AltAutomatic",
      level: 20,
      power: 1_000,
      is_primary: false
    )
    mission = Mission.create!(
      guild: user.guild,
      name: "Atualizar secundário não conta",
      description: "Somente personagem principal deve contar.",
      mission_type: "automatic",
      frequency: "weekly",
      reward_mode: "fixed",
      reward_xp: 15,
      reward_currency: 5,
      metadata: { "trigger" => "primary_character_updated" }
    )

    assert_no_difference -> { MissionSubmission.where(mission: mission, user: user).count } do
      AutomaticMissionEvaluator.evaluate_primary_character_update!(character: secondary)
    end
  end

  test "recompensa missão automática de primeiro login da semana" do
    user = users(:five)
    mission = Mission.create!(
      guild: user.guild,
      name: "Login semanal",
      description: "Entre uma vez por semana.",
      mission_type: "automatic",
      frequency: "weekly",
      reward_mode: "fixed",
      reward_xp: 10,
      reward_currency: 2,
      metadata: { "trigger" => "first_login_of_week" }
    )

    assert_difference -> { MissionSubmission.where(mission: mission, user: user).count }, 1 do
      AutomaticMissionEvaluator.evaluate_first_login_of_week!(user: user)
    end
  end

  test "recompensa missão automática por presença acumulada em evento" do
    user = users(:five)
    event = Event.create!(
      guild: user.guild,
      creator: users(:one),
      title: "Evento automático",
      event_type: "raid",
      starts_at: 2.days.ago,
      ends_at: 2.days.ago + 1.hour,
      status: "completed"
    )
    participation = event.event_participations.find_or_create_by!(user: user) do |record|
      record.rsvp_status = "confirmed"
      record.final_status = "participated"
      record.attended = true
      record.rewarded_at = Time.current
    end
    participation.update!(
      rsvp_status: "confirmed",
      final_status: "participated",
      attended: true,
      rewarded_at: Time.current
    )
    mission = Mission.create!(
      guild: user.guild,
      name: "Participar de evento",
      description: "Participe de um evento.",
      mission_type: "automatic",
      frequency: "weekly",
      reward_mode: "fixed",
      reward_xp: 10,
      metadata: { "trigger" => "event_attended_count", "min_count" => 1 }
    )

    assert_difference -> { MissionSubmission.where(mission: mission, user: user).count }, 1 do
      AutomaticMissionEvaluator.evaluate_event_attended_count!(participation: participation)
    end
  end

  test "não recompensa presença acumulada abaixo do mínimo" do
    user = users(:five)
    event = Event.create!(
      guild: user.guild,
      creator: users(:one),
      title: "Evento abaixo do mínimo",
      event_type: "raid",
      starts_at: 2.days.ago,
      ends_at: 2.days.ago + 1.hour,
      status: "completed"
    )
    participation = event.event_participations.find_by!(user: user)
    participation.update!(rsvp_status: "confirmed", final_status: "participated", attended: true)
    mission = Mission.create!(
      guild: user.guild,
      name: "Participar de três eventos",
      description: "Exige mais presença acumulada.",
      mission_type: "automatic",
      frequency: "weekly",
      reward_mode: "fixed",
      reward_xp: 10,
      metadata: { "trigger" => "event_attended_count", "min_count" => 3 }
    )

    assert_no_difference -> { MissionSubmission.where(mission: mission, user: user).count } do
      AutomaticMissionEvaluator.evaluate_event_attended_count!(participation: participation)
    end
  end

  test "recompensa missão automática por streak de missões recompensadas" do
    user = users(:five)
    first_submission = MissionSubmission.create!(
      mission: missions(:one),
      user: user,
      week_reference: "2026-W70",
      period_sequence: 1,
      status: "rewarded",
      rewarded_at: Time.current
    )
    MissionSubmission.create!(
      mission: missions(:two),
      user: user,
      week_reference: "2026-W70",
      period_sequence: 1,
      status: "rewarded",
      rewarded_at: Time.current
    )
    mission = Mission.create!(
      guild: user.guild,
      name: "Duas missões recompensadas",
      description: "Recompensa streak de missões.",
      mission_type: "automatic",
      frequency: "weekly",
      reward_mode: "fixed",
      reward_xp: 12,
      reward_currency: 4,
      metadata: { "trigger" => "mission_completed_streak", "min_count" => 2 }
    )

    assert_difference -> { MissionSubmission.where(mission: mission, user: user).count }, 1 do
      AutomaticMissionEvaluator.evaluate_mission_completed_streak!(submission: first_submission)
    end
  end
end
