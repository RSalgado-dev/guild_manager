require "application_system_test_case"

class AdminAuditSmokeTest < ApplicationSystemTestCase
  setup do
    @admin = users(:one)
    @admin.update!(has_guild_access: true)
    AuditLog.record!(
      action: "smoke_admin_audit",
      actor: @admin,
      entity: @admin,
      metadata: { "origin" => "test", "result" => "success" }
    )
  end

  test "admin can open audit logs from active admin" do
    system_sign_in(@admin, visit_after_sign_in: nil)

    visit admin_audit_logs_path

    assert_text "Audit Logs"
    assert_text "smoke_admin_audit"
  end
end
