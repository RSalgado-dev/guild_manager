require "test_helper"

class Access::MissionsControllerTest < ActionDispatch::IntegrationTest
  test "usuário lista missões ativas" do
    sign_in(users(:two))

    get missions_path

    assert_response :success
    assert_includes response.body, missions(:one).name
    assert_not_includes response.body, missions(:three).name
  end

  test "usuário envia submissão manual" do
    user = users(:five)
    mission = missions(:one)
    travel_to Time.zone.parse("2026-05-02 12:00:00") do
      sign_in(user)

      assert_difference -> { MissionSubmission.where(mission: mission, user: user).count }, 1 do
        assert_difference -> { AuditLog.where(action: "mission_submission_created").count }, 1 do
          post submit_mission_path(mission), params: {
            mission_submission: {
              quantity: 2,
              notes: "Completei duas rodadas"
            }
          }
        end
      end
    end

    assert_redirected_to mission_path(mission)
    submission = MissionSubmission.where(mission: mission, user: user).order(:created_at).last
    assert_equal "pending", submission.status
    assert_equal 2, submission.quantity
    assert_equal "2026-W18", submission.week_reference
    assert_equal "user", AuditLog.where(action: "mission_submission_created").last.metadata["origin"]
  end

  test "usuário não ultrapassa limite do período" do
    user = users(:five)
    mission = missions(:one)
    period = "2026-W18"
    MissionSubmission.create!(mission: mission, user: user, week_reference: period, period_sequence: 1)

    travel_to Time.zone.parse("2026-05-02 12:00:00") do
      sign_in(user)

      assert_no_difference -> { MissionSubmission.where(mission: mission, user: user).count } do
        post submit_mission_path(mission), params: {
          mission_submission: {
            quantity: 1
          }
        }
      end
    end

    assert_redirected_to mission_path(mission)
    assert_equal "❌ Limite de submissões atingido para este período.", flash[:alert]
  end
end
