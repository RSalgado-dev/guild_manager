require "test_helper"
require "ostruct"

class UserTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    user = User.new(
      guild: guilds(:one),
      discord_id: "999999999999999999",
      discord_username: "test_user",
      xp_points: 100,
      currency_balance: 500
    )
    assert user.valid?
  end

  test "não deve ser válido sem discord_id" do
    user = User.new(guild: guilds(:one), discord_username: "test_user")
    assert_not user.valid?
    assert_includes user.errors[:discord_id], "can't be blank"
  end

  test "não deve ser válido com discord_id duplicado" do
    user = User.new(
      guild: guilds(:one),
      discord_id: users(:one).discord_id
    )
    assert_not user.valid?
    assert_includes user.errors[:discord_id], "has already been taken"
  end

  test "não deve ser válido com xp_points negativo" do
    user = User.new(
      guild: guilds(:one),
      discord_id: "888888888888888888",
      xp_points: -10
    )
    assert_not user.valid?
    assert_includes user.errors[:xp_points], "must be greater than or equal to 0"
  end

  test "não deve ser válido com currency_balance negativo" do
    user = User.new(
      guild: guilds(:one),
      discord_id: "888888888888888888",
      currency_balance: -50
    )
    assert_not user.valid?
    assert_includes user.errors[:currency_balance], "must be greater than or equal to 0"
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    user = users(:one)
    assert_respond_to user, :guild
    assert_instance_of Guild, user.guild
  end

  test "deve pertencer opcionalmente a um esquadrão" do
    user = users(:one)
    assert_respond_to user, :squad
  end

  test "deve ter muitos user_roles" do
    user = users(:one)
    assert_respond_to user, :user_roles
  end

  test "deve ter muitos cargos através de user_roles" do
    user = users(:one)
    assert_respond_to user, :roles
  end

  test "deve ter muitos audit_logs" do
    user = users(:one)
    assert_respond_to user, :audit_logs
  end

  # === Métodos ===

  test "#admin? deve retornar true quando usuário tem cargo admin" do
    user = users(:one) # tem role(:one) que é admin
    assert user.admin?
  end

  test "#admin? deve retornar false quando usuário não tem cargo admin" do
    user = users(:two) # tem role(:two) que não é admin
    assert_not user.admin?
  end

  test "#admin_panel_access? retorna true para usuário com grupos de permissão" do
    user = users(:two)

    assert user.manage_area_access?
    assert_not user.admin_panel_access?
  end

  test "#admin_panel_access? retorna true somente para cargo máximo" do
    user = users(:one)

    assert user.maximum_role?
    assert user.admin_panel_access?
  end

  test "#admin_panel_access? retorna false sem admin nem grupo de permissão" do
    user = users(:five)

    assert_not user.admin?
    assert_not user.manage_area_access?
    assert_not user.admin_panel_access?
  end

  test "#primary_role deve retornar o cargo primário" do
    user = users(:one)
    primary_role = user.primary_role
    assert_not_nil primary_role
    assert_instance_of Role, primary_role
  end

  test "#primary_role deve retornar primeiro cargo se não houver primário" do
    user = users(:one)
    # Remover flag primary de todos os cargos
    user.user_roles.update_all(primary: false)
    primary_role = user.primary_role
    assert_not_nil primary_role
  end

  test "#level segue progressão acumulada com crescimento de 20%" do
    user = users(:one)

    user.xp_points = 0
    assert_equal 0, user.level

    user.xp_points = 100
    assert_equal 1, user.level

    user.xp_points = 219
    assert_equal 1, user.level

    user.xp_points = 220
    assert_equal 2, user.level

    user.xp_points = 364
    assert_equal 3, user.level
  end

  test "#xp_progress_percentage usa faixa do nível atual" do
    user = users(:one)
    user.xp_points = 250

    assert_equal 2, user.level
    assert_equal 364, user.xp_for_next_level
    assert_in_delta 20.8, user.xp_progress_percentage, 0.1
  end

  # === OAuth Discord ===

  test "find_or_create_from_discord deve retornar nil se usuário não pertence a guild configurada" do
    # Mock de auth sem guilds configuradas
    auth = OpenStruct.new(
      uid: "123456789",
      info: OpenStruct.new(
        name: "TestUser",
        image: "http://example.com/avatar.png"
      ),
      credentials: OpenStruct.new(
        token: "fake_access_token"
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          guilds: [
            { "id" => "999999999999999999", "name" => "Servidor Não Configurado" }
          ]
        )
      )
    )

    # Stub da API Discord
    stub_discord_user_guilds(
      access_token: "fake_access_token",
      guilds: [ { "id" => "999999999999999999", "name" => "Servidor Não Configurado" } ]
    )

    user = User.find_or_create_from_discord(auth)
    assert_nil user, "Usuário não deveria ser criado sem guild configurada"
  end

  test "find_or_create_from_discord deve criar usuário se pertence a guild configurada" do
    guild = guilds(:one)
    discord_guild_id = guild.discord_guild_id

    auth = OpenStruct.new(
      uid: "987654321",
      info: OpenStruct.new(
        name: "NewUser",
        image: "http://example.com/avatar.png"
      ),
      credentials: OpenStruct.new(
        token: "fake_access_token"
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          guilds: [
            { "id" => discord_guild_id, "name" => "Servidor Configurado" }
          ]
        )
      )
    )

    # Stub da API Discord
    stub_discord_user_guilds(
      access_token: "fake_access_token",
      guilds: [ { "id" => discord_guild_id, "name" => "Servidor Configurado" } ]
    )

    # Stub para sync_discord_roles
    stub_discord_guild_member(
      guild_id: discord_guild_id,
      user_id: "987654321",
      roles: []
    )
    stub_discord_guild_roles(
      guild_id: discord_guild_id,
      roles: []
    )

    assert_difference "User.count", 1 do
      user = User.find_or_create_from_discord(auth)
      assert_not_nil user
      assert_equal guild.id, user.guild_id
      assert_equal "NewUser", user.discord_username
    end
  end

  test "find_or_create_from_discord deve atualizar usuário existente" do
    user = users(:one)
    guild = guilds(:one)

    auth = OpenStruct.new(
      uid: user.discord_id,
      info: OpenStruct.new(
        name: "UpdatedUsername",
        image: "http://example.com/new_avatar.png"
      ),
      credentials: OpenStruct.new(
        token: "fake_access_token"
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          guilds: [
            { "id" => guild.discord_guild_id, "name" => "Servidor" }
          ]
        )
      )
    )

    # Stub da API Discord
    stub_discord_user_guilds(
      access_token: "fake_access_token",
      guilds: [ { "id" => guild.discord_guild_id, "name" => "Servidor" } ]
    )

    # Stub para sync_discord_roles
    stub_discord_guild_member(
      guild_id: guild.discord_guild_id,
      user_id: user.discord_id,
      roles: []
    )
    stub_discord_guild_roles(
      guild_id: guild.discord_guild_id,
      roles: []
    )

    assert_no_difference "User.count" do
      updated_user = User.find_or_create_from_discord(auth)
      assert_equal user.id, updated_user.id
      assert_equal "UpdatedUsername", updated_user.discord_username
    end
  end

  # === Verificação de Acesso ===

  test "check_guild_role_access deve retornar true se guild não tem role obrigatório" do
    guild = guilds(:one)
    guild.update(required_discord_role_id: nil)
    user = users(:one)

    assert user.check_guild_role_access
  end

  test "check_guild_role_access deve verificar role via Discord API quando obrigatório" do
    guild = guilds(:one)
    guild.update(
      required_discord_role_id: "123456789",
      required_discord_role_name: "Membro"
    )
    user = users(:one)

    # Cria o role no banco com o id correto para que o usuário tenha acesso
    role = Role.where(guild: guild, discord_role_id: "123456789").first_or_create! do |r|
      r.name = "Membro Verificado #{Time.now.to_i}"
      r.description = "Membro verificado"
      r.is_admin = false
    end

    # Atribui o role ao usuário
    UserRole.where(user: user, role: role).first_or_create! do |ur|
      ur.primary = false
    end

    result = user.check_guild_role_access
    assert result, "Usuário deveria ter acesso com role correto"
  end

  test "check_guild_role_access deve retornar false se usuário não tem role obrigatório" do
    guild = guilds(:one)
    guild.update(
      required_discord_role_id: "123456789",
      required_discord_role_name: "Membro"
    )
    user = users(:one)

    # Mock do bot_token
    Rails.application.credentials.stubs(:dig).with(:discord, :bot_token).returns("fake_bot_token")

    # Mock da resposta da API Discord sem o role necessário
    response_body = {
      "user" => { "id" => user.discord_id },
      "roles" => [ "987654321" ] # Não inclui 123456789
    }.to_json

    stub_request(:get, "https://discord.com/api/v10/guilds/#{guild.discord_guild_id}/members/#{user.discord_id}")
      .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })

    result = user.check_guild_role_access
    assert_not result, "Usuário não deveria ter acesso sem role correto"
  end

  test "has_permission? deve retornar true quando usuário pertence a grupo com acesso total" do
    user = users(:one) # possui role admin vinculada ao grupo one_admin
    assert user.has_permission?(:manage_members)
    assert user.has_permission?(:manage_store)
    assert user.has_permission?(:manage_events)
    assert user.has_permission?(:manage_certificates)
  end

  test "has_permission? deve retornar true para permissão específica do grupo" do
    user = users(:two) # possui role two vinculada ao grupo one_events
    assert user.has_permission?(:manage_events)
    assert_not user.has_permission?(:manage_store)
  end

  test "sync_discord_roles_if_stale! deve sincronizar quando estiver stale" do
    user = users(:one)
    user.update!(discord_roles_synced_at: 10.minutes.ago)

    user.expects(:sync_discord_roles).with(user.discord_access_token, user.guild).returns(true)
    assert user.sync_discord_roles_if_stale!(max_age: 2.minutes)
  end

  test "sync_discord_roles_if_stale! não deve sincronizar quando recente" do
    user = users(:one)
    user.update!(discord_roles_synced_at: Time.current)

    user.expects(:sync_discord_roles).never
    assert_not user.sync_discord_roles_if_stale!(max_age: 2.minutes)
  end

  test "sync_discord_roles_if_stale! deve sincronizar com force" do
    user = users(:one)
    user.update!(discord_roles_synced_at: Time.current)

    user.expects(:sync_discord_roles).with(user.discord_access_token, user.guild).returns(true)
    assert user.sync_discord_roles_if_stale!(max_age: 2.minutes, force: true)
  end

  test "tokens Discord são criptografados no banco" do
    user = User.create!(
      guild: guilds(:one),
      discord_id: "999999999999999991",
      discord_username: "encrypted_user",
      discord_access_token: "plain_access_token",
      discord_refresh_token: "plain_refresh_token"
    )

    raw = User.connection.select_one("SELECT discord_access_token, discord_refresh_token FROM users WHERE id = #{user.id}")

    assert_not_equal "plain_access_token", raw["discord_access_token"]
    assert_not_equal "plain_refresh_token", raw["discord_refresh_token"]
    assert_equal "plain_access_token", user.reload.discord_access_token
    assert_equal "plain_refresh_token", user.discord_refresh_token
  end

  test "renova access token expirado com refresh token" do
    user = users(:five)
    user.update!(
      discord_access_token: "old_access",
      discord_refresh_token: "old_refresh",
      discord_token_expires_at: 1.minute.ago
    )
    client = mock("discord_client")
    client.expects(:refresh_access_token).with("old_refresh").returns(
      "access_token" => "new_access",
      "refresh_token" => "new_refresh",
      "expires_in" => 3600
    )

    assert user.refresh_discord_access_token_if_expired!(client: client)
    assert_equal "new_access", user.reload.discord_access_token
    assert_equal "new_refresh", user.discord_refresh_token
    assert user.discord_token_expires_at > 30.minutes.from_now
  end
end
