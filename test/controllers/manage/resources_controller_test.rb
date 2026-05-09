require "test_helper"

class Manage::ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "cargo máximo concede certificado dentro da aplicação" do
    sign_in(users(:one))

    assert_difference("UserCertificate.count", 1) do
      post manage_resources_path("user_certificates"), params: {
        user_certificate: {
          user_id: users(:five).id,
          certificate_id: certificates(:one).id,
          status: "granted"
        }
      }
    end

    grant = UserCertificate.order(:created_at).last
    assert_redirected_to manage_resource_path("user_certificates", grant)
    assert_equal users(:one), grant.granted_by
    assert_equal users(:five), grant.user
    assert grant.granted?
  end

  test "permissão delegada de eventos cria evento em /manage" do
    sign_in(users(:two))

    assert_difference("Event.count", 1) do
      post manage_resources_path("events"), params: {
        event: {
          title: "Operação delegada",
          description: "Criada pela área de gestão",
          event_type: "raid",
          starts_at: 2.days.from_now,
          ends_at: 2.days.from_now + 2.hours,
          recurrence: "unique",
          reward_xp: 100,
          reward_currency: 50
        }
      }
    end

    event = Event.order(:created_at).last
    assert_redirected_to manage_resource_path("events", event)
    assert_equal users(:two), event.creator
  end

  test "permissão delegada não acessa módulo sem permissão" do
    sign_in(users(:two))

    get manage_resources_path("store_items")

    assert_redirected_to manage_root_path
  end

  test "permissão delegada não cria cargo máximo usando valor persistido do enum" do
    permission_groups(:one_members).update!(permissions: [ "manage_roles" ])
    sign_in(users(:two))

    assert_no_difference("Role.count") do
      post manage_resources_path("roles"), params: {
        role: {
          name: "Cargo Máximo via Request",
          description: "Tentativa direta pelo valor persistido do enum",
          category: "maximum",
          managed_by_app: false,
          is_admin: true
        }
      }
    end

    assert_response :not_found
  end

  test "permissão delegada não atribui cargo máximo a usuário" do
    sign_in(users(:two))

    patch manage_resource_path("users", users(:five)), params: {
      user: {
        discord_id: users(:five).discord_id,
        discord_username: users(:five).discord_username,
        has_guild_access: true,
        xp_points: users(:five).xp_points,
        currency_balance: users(:five).currency_balance,
        role_ids: [ roles(:one).id ]
      }
    }

    assert_response :not_found
    assert_not users(:five).roles.reload.exists?(roles(:one).id)
  end

  test "permissão delegada não atribui cargo de outra guilda a usuário" do
    sign_in(users(:two))

    assert_no_changes -> { users(:five).reload.role_ids.sort } do
      patch manage_resource_path("users", users(:five)), params: {
        user: {
          role_ids: [ roles(:three).id ]
        }
      }
    end

    assert_response :not_found
  end

  test "cargo máximo não concede certificado para usuário de outra guilda" do
    sign_in(users(:one))

    assert_no_difference("UserCertificate.count") do
      post manage_resources_path("user_certificates"), params: {
        user_certificate: {
          user_id: users(:three).id,
          certificate_id: certificates(:one).id,
          status: "granted"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "deve pertencer"
  end

  test "cargo máximo não concede conquista para usuário de outra guilda" do
    sign_in(users(:one))

    assert_no_difference("UserAchievement.count") do
      post manage_resources_path("user_achievements"), params: {
        user_achievement: {
          user_id: users(:three).id,
          achievement_id: achievements(:one).id
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "deve pertencer"
  end
end
