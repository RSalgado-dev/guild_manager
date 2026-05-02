require "test_helper"

class MissionSubmissionTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    submission = MissionSubmission.new(
      mission: missions(:two),
      user: users(:three),
      week_reference: "2026-W03"
    )
    assert submission.valid?
  end

  test "não deve ser válido sem missão" do
    submission = MissionSubmission.new(
      user: users(:one),
      week_reference: "2026-W03"
    )
    assert_not submission.valid?
  end

  test "não deve ser válido sem usuário" do
    submission = MissionSubmission.new(
      mission: missions(:one),
      week_reference: "2026-W03"
    )
    assert_not submission.valid?
  end

  test "preenche week_reference automaticamente quando há missão" do
    submission = MissionSubmission.new(
      mission: missions(:one),
      user: users(:one)
    )

    assert submission.valid?
    assert_not_nil submission.week_reference
  end

  test "não deve permitir combinação duplicada de mission, user e week_reference" do
    # mission_submissions(:one) já tem mission:one, user:one, week_reference:"2026-W03"
    submission = MissionSubmission.new(
      mission: missions(:one),
      user: users(:one),
      week_reference: "2026-W03"
    )
    assert_not submission.valid?
    assert_includes submission.errors[:mission_id], "has already been taken"
  end

  test "deve permitir mesmo usuário e missão em semanas diferentes" do
    submission = MissionSubmission.new(
      mission: missions(:one),
      user: users(:one),
      week_reference: "2026-W04"
    )
    assert submission.valid?
  end

  test "deve permitir usuários diferentes na mesma missão e semana" do
    submission = MissionSubmission.new(
      mission: missions(:one),
      user: users(:three),
      week_reference: "2026-W03"
    )
    assert submission.valid?
  end

  test "deve permitir missões diferentes para o mesmo usuário na mesma semana" do
    submission = MissionSubmission.new(
      mission: missions(:two),
      user: users(:one),
      week_reference: "2026-W03"
    )
    assert submission.valid?
  end

  # === Relacionamentos ===

  test "deve pertencer a uma missão" do
    submission = mission_submissions(:one)
    assert_respond_to submission, :mission
    assert_instance_of Mission, submission.mission
  end

  test "deve pertencer a um usuário" do
    submission = mission_submissions(:one)
    assert_respond_to submission, :user
    assert_instance_of User, submission.user
  end

  # === Métodos ===

  test "#week deve retornar week_reference" do
    submission = mission_submissions(:one)
    assert_equal submission.week_reference, submission.week
  end

  # === Campos JSON ===

  test "answers_json pode ser nil" do
    submission = MissionSubmission.new(
      mission: missions(:one),
      user: users(:three),
      week_reference: "2026-W05",
      answers_json: nil
    )
    assert submission.valid?
  end

  test "answers_json pode conter JSON válido" do
    submission = mission_submissions(:one)
    assert_not_nil submission.answers_json
    assert_kind_of String, submission.answers_json
  end

  # === Campos de Recompensa ===

  test "rewarded_at pode ser nil" do
    submission = mission_submissions(:three)
    assert_nil submission.rewarded_at
  end

  test "rewarded_at pode ter uma data" do
    submission = mission_submissions(:one)
    assert_not_nil submission.rewarded_at
    assert_instance_of ActiveSupport::TimeWithZone, submission.rewarded_at
  end

  # === Validação de Week Reference ===

  test "week_reference deve seguir formato ISO 8601" do
    submission = MissionSubmission.new(
      mission: missions(:one),
      user: users(:three),
      week_reference: "2026-W10"
    )
    assert submission.valid?
  end

  test "permite múltiplas submissões no mesmo período com sequência diferente" do
    mission = missions(:one)
    mission.update!(max_submissions_per_period: 2)

    submission = MissionSubmission.new(
      mission: mission,
      user: users(:one),
      week_reference: "2026-W03",
      period_sequence: 2
    )

    assert submission.valid?
  end

  test "aprova, recompensa e impede recompensa duplicada" do
    submission = MissionSubmission.create!(
      mission: missions(:one),
      user: users(:five),
      week_reference: "2026-W30",
      quantity: 1
    )
    reviewer = users(:one)
    original_xp = submission.user.xp_points
    original_currency = submission.user.currency_balance

    submission.approve!(reviewer: reviewer, notes: "ok")
    assert_equal "approved", submission.status
    assert_equal 50, submission.reward_xp_awarded
    assert_equal 100, submission.reward_currency_awarded
    assert_equal reviewer, submission.reviewer

    assert_difference -> { CurrencyTransaction.count }, 1 do
      submission.reward!(reviewer: reviewer)
    end

    assert_equal "rewarded", submission.reload.status
    assert_equal original_xp + 50, submission.user.reload.xp_points
    assert_equal original_currency + 100, submission.user.currency_balance

    assert_raises(ArgumentError) { submission.reward!(reviewer: reviewer) }
  end

  test "rejeita submissão sem recompensa" do
    submission = MissionSubmission.create!(
      mission: missions(:one),
      user: users(:five),
      week_reference: "2026-W31"
    )

    submission.reject!(reviewer: users(:one), notes: "faltou comprovante")

    assert_equal "rejected", submission.status
    assert_equal "faltou comprovante", submission.review_notes
    assert_equal 0, submission.reward_xp_awarded
    assert_equal 0, submission.reward_currency_awarded
  end
end
