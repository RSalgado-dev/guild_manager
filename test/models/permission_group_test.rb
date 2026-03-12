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
    assert group.permission_enabled?(:manage_members)
    assert group.permission_enabled?(:manage_store)
    assert group.permission_enabled?(:manage_events)
    assert group.permission_enabled?(:manage_certificates)
  end
end
