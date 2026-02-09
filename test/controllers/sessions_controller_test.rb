require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @guild = guilds(:one)
  end

  # === Callback OAuth - Sucesso ===

  test "deve criar sessão para usuário válido com acesso" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({
      provider: "discord",
      uid: "123456789",
      info: {
        name: "TestUser",
        email: "test@example.com",
        image: "http://example.com/avatar.png"
      },
      credentials: {
        token: "fake_access_token"
      },
      extra: {
        raw_info: {
          guilds: [
            { "id" => @guild.discord_guild_id, "name" => "Test Guild" }
          ]
        }
      }
    })

    # Mock da verificação de role (sem role obrigatório)
    @guild.update(required_discord_role_id: nil)

    # Stub da API Discord
    stub_discord_user_guilds(
      access_token: "fake_access_token",
      guilds: [ { "id" => @guild.discord_guild_id, "name" => "Test Guild" } ]
    )

    # Stub para sync_discord_roles
    stub_discord_guild_member(
      guild_id: @guild.discord_guild_id,
      user_id: "123456789",
      roles: []
    )
    stub_discord_guild_roles(
      guild_id: @guild.discord_guild_id,
      roles: []
    )

    get "/auth/discord/callback"

    assert_response :redirect
    assert_redirected_to root_path
    assert session[:user_id].present?, "Sessão deveria ser criada"

    user = User.find_by(discord_id: "123456789")
    assert_not_nil user, "Usuário deveria ser criado"
    assert_equal "TestUser", user.discord_username
  end

  test "deve criar audit log ao fazer login" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({
      provider: "discord",
      uid: "987654321",
      info: {
        name: "AnotherUser",
        email: "another@example.com",
        image: "http://example.com/avatar2.png"
      },
      credentials: {
        token: "fake_access_token"
      },
      extra: {
        raw_info: {
          guilds: [
            { "id" => @guild.discord_guild_id, "name" => "Test Guild" }
          ]
        }
      }
    })

    @guild.update(required_discord_role_id: nil)

    # Stub da API Discord
    stub_discord_user_guilds(
      access_token: "fake_access_token",
      guilds: [ { "id" => @guild.discord_guild_id, "name" => "Test Guild" } ]
    )

    # Stub para sync_discord_roles
    stub_discord_guild_member(
      guild_id: @guild.discord_guild_id,
      user_id: "987654321",
      roles: []
    )
    stub_discord_guild_roles(
      guild_id: @guild.discord_guild_id,
      roles: []
    )

    assert_difference "AuditLog.count", 1 do
      get "/auth/discord/callback"
    end

    user = User.find_by(discord_id: "987654321")
    log = AuditLog.last
    assert_equal "login", log.action
    assert_equal user.id, log.user_id
  end

  # === Callback OAuth - Falhas ===

  test "não deve criar sessão se usuário não pertence a guild configurada" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({
      provider: "discord",
      uid: "111111111",
      info: {
        name: "OutsiderUser",
        email: "outsider@example.com",
        image: "http://example.com/avatar3.png"
      },
      credentials: {
        token: "fake_access_token"
      },
      extra: {
        raw_info: {
          guilds: [
            { "id" => "999999999999999999", "name" => "Other Guild" }
          ]
        }
      }
    })

    # Stub da API Discord
    stub_discord_user_guilds(
      access_token: "fake_access_token",
      guilds: [ { "id" => "999999999999999999", "name" => "Other Guild" } ]
    )

    get "/auth/discord/callback"

    assert_response :redirect
    assert_redirected_to root_path
    assert_nil session[:user_id], "Sessão não deveria ser criada"
    assert_match /Nenhum servidor Discord encontrado/, flash[:alert]
  end

  test "deve redirecionar para restricted se usuário não tem role obrigatório" do
    @guild.update(
      required_discord_role_id: "123456789",
      required_discord_role_name: "Membro Verificado"
    )

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({
      provider: "discord",
      uid: "222222222",
      info: {
        name: "UnverifiedUser",
        email: "unverified@example.com",
        image: "http://example.com/avatar4.png"
      },
      credentials: {
        token: "fake_access_token"
      },
      extra: {
        raw_info: {
          guilds: [
            { "id" => @guild.discord_guild_id, "name" => "Test Guild" }
          ]
        }
      }
    })

    # Stub da API Discord
    stub_discord_user_guilds(
      access_token: "fake_access_token",
      guilds: [ { "id" => @guild.discord_guild_id, "name" => "Test Guild" } ]
    )

    # Stub para sync_discord_roles
    stub_discord_guild_member(
      guild_id: @guild.discord_guild_id,
      user_id: "222222222",
      roles: [ "987654321" ]
    )
    stub_discord_guild_roles(
      guild_id: @guild.discord_guild_id,
      roles: [
        { "id" => "987654321", "name" => "Outro Role" }
      ]
    )

    # Mock da API Discord retornando sem o role necessário
    response_body = {
      "user" => { "id" => "222222222" },
      "roles" => [ "987654321" ]
    }.to_json

    stub_request(:get, "https://discord.com/api/v10/guilds/#{@guild.discord_guild_id}/members/222222222")
      .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })

    get "/auth/discord/callback"

    assert_response :redirect
    assert_redirected_to restricted_access_path
  end

  # === Logout ===

  test "deve destruir sessão ao fazer logout" do
    user = users(:one)

    ApplicationController.any_instance.stubs(:current_user).returns(user)

    delete logout_path

    assert_response :redirect
    assert_redirected_to root_path
    assert_equal "Logout realizado com sucesso!", flash[:notice]
  end

  test "deve criar audit log ao fazer logout" do
    user = users(:one)

    ApplicationController.any_instance.stubs(:current_user).returns(user)

    assert_difference "AuditLog.count", 1 do
      delete logout_path
    end

    log = AuditLog.last
    assert_equal "logout", log.action
    assert_equal user.id, log.user_id
  end
end
