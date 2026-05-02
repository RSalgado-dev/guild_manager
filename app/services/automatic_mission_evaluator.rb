class AutomaticMissionEvaluator
  PRIMARY_CHARACTER_UPDATED_TRIGGER = "primary_character_updated"

  def self.evaluate_primary_character_update!(character:)
    new(character.user).evaluate_primary_character_update!(character:)
  end

  def initialize(user)
    @user = user
    @guild = user.guild
  end

  def evaluate_primary_character_update!(character:)
    return unless character.is_primary?

    automatic_missions(PRIMARY_CHARACTER_UPDATED_TRIGGER).each do |mission|
      complete_automatic_mission!(mission, character)
    end
  end

  private

  attr_reader :user, :guild

  def automatic_missions(trigger)
    guild.missions.active.automatic.select { |mission| mission.metadata["trigger"] == trigger }
  end

  def complete_automatic_mission!(mission, character)
    period_reference = mission.current_period_reference
    return unless mission.submissions_count_for(user, period_reference) < mission.max_submissions_per_period

    sequence = mission.next_period_sequence_for(user, period_reference)
    reward = mission.reward_for(1)

    submission = MissionSubmission.create!(
      mission: mission,
      user: user,
      week_reference: period_reference,
      period_sequence: sequence,
      quantity: 1,
      status: "approved",
      submitted_at: Time.current,
      reviewed_at: Time.current,
      reward_xp_awarded: reward[:xp],
      reward_currency_awarded: reward[:currency],
      answers_json: {
        "automatic" => true,
        "trigger" => PRIMARY_CHARACTER_UPDATED_TRIGGER,
        "character_id" => character.id,
        "level" => character.level,
        "power" => character.power
      }
    )
    submission.audit!("mission_submission_created", actor: nil)
    submission.reward!
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("Missão automática #{mission.id} não foi concluída para user #{user.id}: #{e.message}")
  end
end
