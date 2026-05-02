require "test_helper"

class PermissionGroupTest < ActiveSupport::TestCase
  test "deve ser válido com permissões suportadas" do
    group = PermissionGroup.new(
      guild: guilds(:one),
      name: "Loja",
      all_access: false,
      permissions: [ "manage_store" ],
      roles: [ roles(:two) ]
    )

    assert group.valid?
  end

  test "não deve aceitar permissões inválidas" do
    group = PermissionGroup.new(
      guild: guilds(:one),
      name: "Inválido",
      all_access: false,
      permissions: [ "hacker_mode" ],
      roles: [ roles(:two) ]
    )

    assert_not group.valid?
    assert_includes group.errors[:permissions].join, "inválidas"
  end

  test "não deve aceitar grupo sem role quando não é acesso total" do
    group = PermissionGroup.new(
      guild: guilds(:one),
      name: "Sem Role",
      all_access: false,
      permissions: [ "manage_members" ]
    )

    assert_not group.valid?
    assert_includes group.errors[:roles], "deve ter ao menos uma role do Discord vinculada"
  end

  test "all_access deve habilitar todas permissões" do
    group = permission_groups(:one_admin)

    PermissionGroup::AVAILABLE_PERMISSIONS.each do |permission|
      assert group.permission_enabled?(permission), "Esperava que #{permission} estivesse habilitada"
    end
  end

  test "deve suportar catálogo expandido de permissões operacionais" do
    expected_permissions = %w[
      manage_guild_settings
      manage_roles
      manage_administrative_roles
      manage_members
      manage_events
      manage_missions
      review_mission_submissions
      manage_achievements
      grant_achievements
      manage_certificates
      grant_certificates
      manage_rankings
      manage_store
      fulfill_store_orders
      view_audit_logs
    ]

    assert_equal expected_permissions, PermissionGroup::AVAILABLE_PERMISSIONS
  end
end
