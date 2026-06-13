require "test_helper"

class Manage::ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "cargo máximo lista e visualiza recursos da gestão" do
    sign_in(users(:one))

    get manage_resources_path("missions")
    assert_response :success
    assert_includes response.body, "Missões"
    assert_includes response.body, missions(:one).name

    get manage_resource_path("missions", missions(:one))
    assert_response :success
    assert_includes response.body, missions(:one).name
    assert_includes response.body, "Editar"
  end

  test "cargo máximo abre formulário de novo recurso com guilda padrão" do
    sign_in(users(:one))

    get manage_new_resource_path("missions")

    assert_response :success
    assert_includes response.body, "Novo registro"
    assert_includes response.body, "Metadados"
  end

  test "recurso somente leitura bloqueia formulário" do
    sign_in(users(:one))

    get manage_new_resource_path("audit_logs")

    assert_redirected_to manage_resources_path("audit_logs")
    assert_equal "❌ Este recurso é somente leitura.", flash[:alert]
  end

  test "recurso sem criação bloqueia formulário" do
    sign_in(users(:one))

    get manage_new_resource_path("store_orders")

    assert_redirected_to manage_resources_path("store_orders")
    assert_equal "❌ Este recurso não permite criação.", flash[:alert]
  end

  test "cargo máximo atualiza recurso e audita" do
    sign_in(users(:one))
    mission = missions(:one)

    assert_difference -> { AuditLog.where(action: "manage_resource_updated").count }, 1 do
      patch manage_resource_path("missions", mission), params: {
        mission: {
          name: "Missão Gerenciada",
          description: mission.description,
          mission_type: mission.mission_type,
          frequency: mission.frequency,
          reward_mode: mission.reward_mode,
          reward_xp: mission.reward_xp,
          reward_currency: mission.reward_currency,
          reward_xp_per_unit: mission.reward_xp_per_unit,
          reward_currency_per_unit: mission.reward_currency_per_unit,
          max_submissions_per_period: mission.max_submissions_per_period,
          metadata_json: '{ "managed": true }',
          active: mission.active
        }
      }
    end

    assert_redirected_to manage_resource_path("missions", mission)
    assert_equal "Missão Gerenciada", mission.reload.name
    assert_equal({ "managed" => true }, mission.metadata)
  end

  test "atualização inválida renderiza edição" do
    sign_in(users(:one))
    mission = missions(:one)

    patch manage_resource_path("missions", mission), params: {
      mission: {
        name: "",
        metadata_json: "{invalid"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Não foi possível salvar"
  end

  test "cargo máximo remove recurso e audita" do
    sign_in(users(:one))
    ranking = Ranking.create!(
      guild: users(:one).guild,
      name: "Ranking temporário",
      ranking_scope: "users",
      metric: "user_xp",
      sort_direction: "desc",
      entries_limit: 10
    )

    assert_difference("Ranking.count", -1) do
      assert_difference -> { AuditLog.where(action: "manage_resource_destroyed").count }, 1 do
        delete manage_resource_path("rankings", ranking)
      end
    end

    assert_redirected_to manage_resources_path("rankings")
  end

  test "remoção bloqueada retorna para o recurso" do
    sign_in(users(:one))
    buyer = users(:five)
    buyer.update!(currency_balance: 100)
    item = StoreItem.create!(guild: buyer.guild, name: "Item com pedido", price: 10, stock_quantity: 1)
    StoreOrder.checkout!(user: buyer, store_item: item)

    assert_no_difference("StoreItem.count") do
      delete manage_resource_path("store_items", item)
    end

    assert_redirected_to manage_resource_path("store_items", item)
    assert_includes flash[:alert], "Cannot delete record"
  end

  test "listagens especiais respeitam escopo da guilda" do
    sign_in(users(:one))
    resources = {
      "store_orders" => "Pedidos da Loja",
      "user_certificates" => "Concessões de Certificado",
      "user_achievements" => "Concessões de Conquista",
      "mission_submissions" => "Submissões",
      "audit_logs" => "Auditoria"
    }

    resources.each do |resource_key, title|
      get manage_resources_path(resource_key)

      assert_response :success
      assert_includes response.body, title
    end
  end

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

  test "ação inválida em recurso retorna alerta" do
    sign_in(users(:one))
    buyer = users(:five)
    buyer.update!(currency_balance: 100)
    item = StoreItem.create!(guild: buyer.guild, name: "Pedido ação inválida", price: 10, stock_quantity: 1)
    order = StoreOrder.checkout!(user: buyer, store_item: item)

    post manage_resource_action_path("store_orders", order, "invalid_action")

    assert_redirected_to manage_resource_path("store_orders", order)
    assert_equal "❌ Ação inválida.", flash[:alert]
  end

  test "ação de gestão sincroniza acesso da guilda" do
    sign_in(users(:one))
    User.any_instance.stubs(:check_guild_role_access).returns(true)

    assert_difference -> { AuditLog.where(action: "guild_access_synced").count }, 1 do
      post manage_resource_action_path("guild", users(:one).guild, "sync_access")
    end

    assert_redirected_to manage_resource_path("guild", users(:one).guild)
  end

  test "ação de gestão verifica acesso de usuário" do
    sign_in(users(:one))
    checked_user = users(:five)
    User.any_instance.stubs(:check_guild_role_access).returns(true)

    assert_difference -> { AuditLog.where(action: "user_access_checked").count }, 1 do
      post manage_resource_action_path("users", checked_user, "check_access")
    end

    assert_redirected_to manage_resource_path("users", checked_user)
    assert checked_user.reload.has_guild_access
  end

  test "ação de gestão aprova rejeita e recompensa submissão de missão" do
    sign_in(users(:one))
    user = users(:five)
    mission = missions(:one)
    approved_submission = MissionSubmission.create!(
      mission: mission,
      user: user,
      week_reference: "2026-W80",
      period_sequence: 1
    )
    rejected_submission = MissionSubmission.create!(
      mission: mission,
      user: users(:six),
      week_reference: "2026-W80",
      period_sequence: 1
    )

    post manage_resource_action_path("mission_submissions", approved_submission, "approve"), params: { notes: "ok" }
    assert_redirected_to manage_resource_path("mission_submissions", approved_submission)
    assert_equal "approved", approved_submission.reload.status

    post manage_resource_action_path("mission_submissions", approved_submission, "reward")
    assert_redirected_to manage_resource_path("mission_submissions", approved_submission)
    assert_equal "rewarded", approved_submission.reload.status

    post manage_resource_action_path("mission_submissions", rejected_submission, "reject"), params: { notes: "" }
    assert_redirected_to manage_resource_path("mission_submissions", rejected_submission)
    assert_equal "rejected", rejected_submission.reload.status
    assert_equal "Rejeitado pela gestão.", rejected_submission.review_notes
  end

  test "ação de gestão aprova e rejeita pedido de missão" do
    sign_in(users(:one))
    approved_request = MissionRequest.create!(
      guild: users(:one).guild,
      requester: users(:five),
      title: "Pedido aprovado pela gestão",
      description: "Criar missão especial."
    )
    rejected_request = MissionRequest.create!(
      guild: users(:one).guild,
      requester: users(:six),
      title: "Pedido rejeitado pela gestão",
      description: "Criar outra missão especial."
    )

    post manage_resource_action_path("mission_requests", approved_request, "approve"), params: { notes: "aprovado" }
    assert_redirected_to manage_resource_path("mission_requests", approved_request)
    assert_equal "approved", approved_request.reload.status

    post manage_resource_action_path("mission_requests", rejected_request, "reject"), params: { notes: "" }
    assert_redirected_to manage_resource_path("mission_requests", rejected_request)
    assert_equal "rejected", rejected_request.reload.status
    assert_equal "Rejeitado pela gestão.", rejected_request.admin_notes
  end

  test "ação de gestão revoga certificado" do
    sign_in(users(:one))
    user_certificate = UserCertificate.create!(
      user: users(:five),
      certificate: certificates(:one),
      granted_by: users(:one)
    )

    post manage_resource_action_path("user_certificates", user_certificate, "revoke")

    assert_redirected_to manage_resource_path("user_certificates", user_certificate)
    assert_equal "revoked", user_certificate.reload.status
  end

  test "ação de gestão entrega rejeita e cancela pedidos da loja" do
    sign_in(users(:one))
    buyer = users(:five)
    buyer.update!(currency_balance: 200)
    fulfilled_item = StoreItem.create!(guild: buyer.guild, name: "Entrega gestão", price: 10, stock_quantity: 1)
    rejected_item = StoreItem.create!(guild: buyer.guild, name: "Rejeição gestão", price: 10, stock_quantity: 1)
    canceled_item = StoreItem.create!(guild: buyer.guild, name: "Cancelamento gestão", price: 10, stock_quantity: 1)
    fulfilled_order = StoreOrder.checkout!(user: buyer, store_item: fulfilled_item)
    rejected_order = StoreOrder.checkout!(user: buyer, store_item: rejected_item)
    canceled_order = StoreOrder.checkout!(user: buyer, store_item: canceled_item)

    post manage_resource_action_path("store_orders", fulfilled_order, "fulfill"), params: { notes: "entregue" }
    assert_redirected_to manage_resource_path("store_orders", fulfilled_order)
    assert_equal "fulfilled", fulfilled_order.reload.status
    assert_equal "entregue", fulfilled_order.admin_notes

    post manage_resource_action_path("store_orders", rejected_order, "reject"), params: { notes: "" }
    assert_redirected_to manage_resource_path("store_orders", rejected_order)
    assert_equal "rejected", rejected_order.reload.status
    assert_equal "Rejeitado pela gestão.", rejected_order.admin_notes

    post manage_resource_action_path("store_orders", canceled_order, "cancel")
    assert_redirected_to manage_resource_path("store_orders", canceled_order)
    assert_equal "canceled", canceled_order.reload.status
  end

  test "ação de gestão aprova e rejeita mudança de perfil de squad" do
    sign_in(users(:one))
    approved_squad = squads(:one)
    approved_squad.request_profile_change!(
      actor: approved_squad.leader,
      attributes: { name: "Alpha Gestão", tag: "ALPGST" }
    )
    rejected_squad = squads(:three)
    rejected_squad.request_profile_change!(
      actor: rejected_squad.leader,
      attributes: { name: "Beta Gestão", tag: "BETGST" }
    )

    post manage_resource_action_path("squads", approved_squad, "approve_profile_change")
    assert_redirected_to manage_resource_path("squads", approved_squad)
    assert_equal "profile_approved", approved_squad.reload.profile_change_status
    assert_equal "Alpha Gestão", approved_squad.name

    post manage_resource_action_path("squads", rejected_squad, "reject_profile_change"), params: { reason: "" }
    assert_redirected_to manage_resource_path("squads", rejected_squad)
    assert_equal "profile_rejected", rejected_squad.reload.profile_change_status
    assert_equal "Rejeitado pela gestão.", rejected_squad.profile_change_rejection_reason
  end

  test "ação de gestão finaliza evento com resultados padrão" do
    sign_in(users(:one))
    event = Event.create!(
      guild: users(:one).guild,
      creator: users(:one),
      title: "Evento padrão gestão",
      event_type: "raid",
      starts_at: 2.days.ago,
      ends_at: 2.days.ago + 2.hours,
      recurrence: "unique",
      reward_xp: 10,
      reward_currency: 5
    )

    post manage_resource_action_path("events", event, "complete_default")

    assert_redirected_to manage_resource_path("events", event)
    assert_equal "completed", event.reload.status
  end

  test "ação de gestão não finaliza evento futuro" do
    sign_in(users(:one))
    event = Event.create!(
      guild: users(:one).guild,
      creator: users(:one),
      title: "Evento futuro gestão",
      event_type: "raid",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 2.hours,
      recurrence: "unique",
      reward_xp: 10,
      reward_currency: 5
    )

    post manage_resource_action_path("events", event, "complete_default")

    assert_redirected_to manage_resource_path("events", event)
    assert_equal "❌ Evento ainda não pode ser finalizado.", flash[:alert]
    assert_equal "scheduled", event.reload.status
  end
end
