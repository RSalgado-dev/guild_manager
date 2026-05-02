require "test_helper"

class MissionTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    mission = Mission.new(
      guild: guilds(:one),
      name: "Missão Teste",
      description: "Descrição da missão",
      frequency: :weekly,
      reward_currency: 100,
      reward_xp: 50,
      active: true
    )
    assert mission.valid?
  end

  test "não deve ser válido sem nome" do
    mission = Mission.new(
      guild: guilds(:one),
      frequency: :weekly,
      reward_currency: 100,
      reward_xp: 50
    )
    assert_not mission.valid?
    assert_includes mission.errors[:name], "can't be blank"
  end

  test "não deve ser válido sem guilda" do
    mission = Mission.new(
      name: "Missão Teste",
      frequency: :weekly
    )
    assert_not mission.valid?
  end

  test "deve validar reward_currency não negativo" do
    mission = Mission.new(
      guild: guilds(:one),
      name: "Missão Teste",
      frequency: :weekly,
      reward_currency: -10,
      reward_xp: 0
    )
    assert_not mission.valid?
    assert_includes mission.errors[:reward_currency], "must be greater than or equal to 0"
  end

  test "deve validar reward_xp não negativo" do
    mission = Mission.new(
      guild: guilds(:one),
      name: "Missão Teste",
      frequency: :weekly,
      reward_currency: 100,
      reward_xp: -10
    )
    assert_not mission.valid?
    assert_includes mission.errors[:reward_xp], "must be greater than or equal to 0"
  end

  test "deve ser válido com reward_currency zero" do
    mission = Mission.new(
      guild: guilds(:one),
      name: "Missão Sem Moeda",
      frequency: :weekly,
      reward_currency: 0,
      reward_xp: 50
    )
    assert mission.valid?
  end

  test "deve ser válido com reward_xp zero" do
    mission = Mission.new(
      guild: guilds(:one),
      name: "Missão Sem XP",
      frequency: :weekly,
      reward_currency: 100,
      reward_xp: 0
    )
    assert mission.valid?
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    mission = missions(:one)
    assert_respond_to mission, :guild
    assert_instance_of Guild, mission.guild
  end

  test "deve ter muitos mission_submissions" do
    mission = missions(:one)
    assert_respond_to mission, :mission_submissions
  end

  test "deve ter muitos usuários através de submissions" do
    mission = missions(:one)
    assert_respond_to mission, :users
  end

  test "deve destruir submissões ao ser destruída" do
    mission = missions(:one)
    submission_count = mission.mission_submissions.count
    assert_difference("MissionSubmission.count", -submission_count) do
      mission.destroy
    end
  end

  # === Enums ===

  test "deve aceitar frequências válidas" do
    mission = missions(:one)

    assert_nothing_raised do
      mission.frequency = :daily
      mission.frequency = :weekly
      mission.frequency = :monthly
    end
  end

  test "deve ter frequência weekly válida" do
    mission = missions(:one)
    assert_equal "weekly", mission.frequency
  end

  # === Validações Numéricas ===

  test "reward_currency deve ser maior ou igual a zero" do
    mission = Mission.new(
      guild: guilds(:one),
      name: "Missão Teste",
      frequency: :weekly,
      reward_currency: -10,
      reward_xp: 50
    )
    assert_not mission.valid?
    assert_includes mission.errors[:reward_currency], "must be greater than or equal to 0"
  end

  test "reward_xp deve ser maior ou igual a zero" do
    mission = Mission.new(
      guild: guilds(:one),
      name: "Missão Teste",
      frequency: :weekly,
      reward_currency: 100,
      reward_xp: -10
    )
    assert_not mission.valid?
    assert_includes mission.errors[:reward_xp], "must be greater than or equal to 0"
  end

  test "calcula período atual por frequência" do
    mission = missions(:one)
    reference_time = Time.zone.parse("2026-05-02 12:00:00")

    mission.frequency = "daily"
    assert_equal "2026-05-02", mission.current_period_reference(reference_time:)

    mission.frequency = "weekly"
    assert_equal "2026-W18", mission.current_period_reference(reference_time:)

    mission.frequency = "monthly"
    assert_equal "2026-05", mission.current_period_reference(reference_time:)
  end

  test "calcula recompensa fixa e por unidade" do
    mission = missions(:one)

    assert_equal({ xp: 50, currency: 100 }, mission.reward_for(3))

    mission.reward_mode = "per_unit"
    mission.reward_xp_per_unit = 7
    mission.reward_currency_per_unit = 11

    assert_equal({ xp: 21, currency: 33 }, mission.reward_for(3))
  end

  test "controla limite de submissões por período" do
    mission = missions(:one)
    user = users(:five)
    period = "2026-W20"

    assert mission.accepts_submission_from?(user, period)
    assert_equal 1, mission.next_period_sequence_for(user, period)

    MissionSubmission.create!(
      mission: mission,
      user: user,
      week_reference: period,
      period_sequence: 1
    )

    assert_not mission.accepts_submission_from?(user, period)
    assert_nil mission.next_period_sequence_for(user, period)
  end
end
