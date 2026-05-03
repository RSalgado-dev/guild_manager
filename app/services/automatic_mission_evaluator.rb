class AutomaticMissionEvaluator
  PRIMARY_CHARACTER_UPDATED_TRIGGER = "primary_character_updated"
  FIRST_LOGIN_OF_WEEK_TRIGGER = "first_login_of_week"
  EVENT_ATTENDED_COUNT_TRIGGER = "event_attended_count"
  MISSION_COMPLETED_STREAK_TRIGGER = "mission_completed_streak"

  def self.evaluate_primary_character_update!(character:)
    new(character.user).evaluate_primary_character_update!(character:)
  end

  def self.evaluate_first_login_of_week!(user:)
    new(user).evaluate_first_login_of_week!
  end

  def self.evaluate_event_attended_count!(participation:)
    new(participation.user).evaluate_event_attended_count!(participation:)
  end

  def self.evaluate_mission_completed_streak!(submission:)
    new(submission.user).evaluate_mission_completed_streak!(submission:)
  end

  def initialize(user)
    @user = user
    @guild = user.guild
  end

  def evaluate_primary_character_update!(character:)
    return unless character.is_primary?

    automatic_missions(PRIMARY_CHARACTER_UPDATED_TRIGGER).each do |mission|
      complete_automatic_mission!(
        mission,
        {
          "trigger" => PRIMARY_CHARACTER_UPDATED_TRIGGER,
          "character_id" => character.id,
          "level" => character.level,
          "power" => character.power
        }
      )
    end
  end

  def evaluate_first_login_of_week!
    automatic_missions(FIRST_LOGIN_OF_WEEK_TRIGGER).each do |mission|
      complete_automatic_mission!(
        mission,
        {
          "trigger" => FIRST_LOGIN_OF_WEEK_TRIGGER,
          "login_at" => Time.current.iso8601
        }
      )
    end
  end

  def evaluate_event_attended_count!(participation:)
    return unless participation.participated?

    attended_count = user.event_participations.participated.count
    automatic_missions(EVENT_ATTENDED_COUNT_TRIGGER).each do |mission|
      required_count = mission.metadata.fetch("min_count", 1).to_i
      next if attended_count < required_count

      complete_automatic_mission!(
        mission,
        {
          "trigger" => EVENT_ATTENDED_COUNT_TRIGGER,
          "event_participation_id" => participation.id,
          "attended_count" => attended_count,
          "min_count" => required_count
        }
      )
    end
  end

  def evaluate_mission_completed_streak!(submission:)
    rewarded_count = user.mission_submissions.rewarded.count
    automatic_missions(MISSION_COMPLETED_STREAK_TRIGGER).each do |mission|
      required_count = mission.metadata.fetch("min_count", 3).to_i
      next if rewarded_count < required_count

      complete_automatic_mission!(
        mission,
        {
          "trigger" => MISSION_COMPLETED_STREAK_TRIGGER,
          "mission_submission_id" => submission.id,
          "rewarded_count" => rewarded_count,
          "min_count" => required_count
        }
      )
    end
  end

  private

  attr_reader :user, :guild

  def automatic_missions(trigger)
    guild.missions.active.automatic.select { |mission| mission.metadata["trigger"] == trigger }
  end

  def complete_automatic_mission!(mission, answers)
    mission.with_lock do
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
        answers_json: answers.merge("automatic" => true)
      )
      submission.audit!("mission_submission_created", actor: nil)
      submission.reward!
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("Missão automática #{mission.id} não foi concluída para user #{user.id}: #{e.message}")
  end
end
