require "test_helper"

class HealthChecksControllerTest < ActionDispatch::IntegrationTest
  test "full health check validates database and queue" do
    Rails.application.credentials.stubs(:dig).with(:discord, :bot_token).returns("fake_bot_token")

    get full_health_check_path

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 200, payload["status"]
    assert_equal true, payload.dig("checks", "database")
    assert_equal true, payload.dig("checks", "solid_queue")
    assert_equal true, payload.dig("checks", "discord_configured")
  end
end
