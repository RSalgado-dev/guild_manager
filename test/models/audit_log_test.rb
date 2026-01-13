require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  # === Validações Básicas ===

  test "deve ser válido com atributos válidos" do
    audit_log = AuditLog.new(
      user: users(:one),
      guild: guilds(:one),
      action: "test_action",
      entity_type: "Squad",
      entity_id: 1
    )
    assert audit_log.valid?
  end

  test "deve ser válido sem usuário (ações do sistema)" do
    audit_log = AuditLog.new(
      guild: guilds(:one),
      action: "system_action",
      entity_type: "Guild",
      entity_id: 1
    )
    assert audit_log.valid?
  end

  test "deve ser válido sem guilda" do
    audit_log = AuditLog.new(
      user: users(:one),
      action: "user_action",
      entity_type: "User",
      entity_id: 1
    )
    assert audit_log.valid?
  end

  # === Relacionamentos ===

  test "deve pertencer opcionalmente a um usuário" do
    audit_log = audit_logs(:one)
    assert_respond_to audit_log, :user
    assert_instance_of User, audit_log.user
  end

  test "deve pertencer opcionalmente a uma guilda" do
    audit_log = audit_logs(:one)
    assert_respond_to audit_log, :guild
    assert_instance_of Guild, audit_log.guild
  end

  # === Método entity ===

  test "#entity deve retornar a entidade relacionada quando válida" do
    squad = squads(:one)
    audit_log = AuditLog.create!(
      user: users(:one),
      guild: guilds(:one),
      action: "test_action",
      entity_type: "Squad",
      entity_id: squad.id
    )
    
    entity = audit_log.entity
    assert_instance_of Squad, entity
    assert_equal squad.id, entity.id
  end

  test "#entity deve retornar nil quando entity_type está em branco" do
    audit_log = AuditLog.new(
      user: users(:one),
      guild: guilds(:one),
      action: "test_action",
      entity_type: nil,
      entity_id: 1
    )
    assert_nil audit_log.entity
  end

  test "#entity deve retornar nil quando entity_id está em branco" do
    audit_log = AuditLog.new(
      user: users(:one),
      guild: guilds(:one),
      action: "test_action",
      entity_type: "Squad",
      entity_id: nil
    )
    assert_nil audit_log.entity
  end

  test "#entity deve retornar nil quando a entidade não existe" do
    audit_log = AuditLog.new(
      user: users(:one),
      guild: guilds(:one),
      action: "test_action",
      entity_type: "Squad",
      entity_id: 999999
    )
    assert_nil audit_log.entity
  end

  test "#entity deve retornar nil quando entity_type é inválido" do
    audit_log = AuditLog.new(
      user: users(:one),
      guild: guilds(:one),
      action: "test_action",
      entity_type: "InvalidModel",
      entity_id: 1
    )
    assert_nil audit_log.entity
  end

  # === Scopes ===

  test "scope recent deve ordenar por criação mais recente" do
    logs = AuditLog.recent.to_a
    assert_equal [ audit_logs(:three), audit_logs(:two), audit_logs(:one) ], logs
  end

  test "scope for_guild deve filtrar por guilda" do
    guild = guilds(:one)
    logs = AuditLog.for_guild(guild.id)
    assert logs.all? { |log| log.guild_id == guild.id }
  end

  test "scope by_action deve filtrar por ação" do
    action = "create_squad"
    logs = AuditLog.by_action(action)
    assert logs.all? { |log| log.action == action }
  end

  test "deve encadear scopes" do
    guild = guilds(:one)
    action = "create_squad"
    logs = AuditLog.for_guild(guild.id).by_action(action).recent

    assert logs.all? { |log| log.guild_id == guild.id && log.action == action }
  end

  # === Uso Prático ===

  test "deve registrar criação de entidade" do
    squad = squads(:one)

    audit_log = AuditLog.create!(
      user: users(:one),
      guild: guilds(:one),
      action: "create",
      entity_type: "Squad",
      entity_id: squad.id
    )

    assert_equal squad, audit_log.entity
  end

  test "deve registrar ação sem entidade específica" do
    audit_log = AuditLog.create!(
      user: users(:one),
      guild: guilds(:one),
      action: "login"
    )

    assert_nil audit_log.entity
    assert_equal "login", audit_log.action
  end
end
