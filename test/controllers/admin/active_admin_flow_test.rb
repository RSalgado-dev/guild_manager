require "test_helper"

class ActiveAdminFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update!(has_guild_access: true)
    sign_in(@admin)
  end

  test "cargo máximo acessa dashboard index e detalhes dos recursos do ActiveAdmin" do
    readable_resources.each do |resource|
      get admin_path_for(resource.fetch(:index_path))
      assert_response :success
      assert_includes response.body, resource.fetch(:index_text)

      get admin_path_for(resource.fetch(:show_path), resource.fetch(:record))
      assert_response :success
      assert_includes response.body, resource.fetch(:show_text)
    end
  end

  test "cargo máximo abre formulários básicos dos recursos editáveis" do
    form_resources.each do |resource|
      if resource[:new_path]
        get admin_path_for(resource.fetch(:new_path))
        assert_response :success
        assert_includes response.body, resource.fetch(:form_text)
      end

      get admin_path_for(resource.fetch(:edit_path), resource.fetch(:record))
      assert_response :success
      assert_includes response.body, resource.fetch(:form_text)
    end
  end

  test "painel técnico bloqueia usuário sem cargo máximo" do
    get logout_path
    sign_in(users(:two))

    get admin_root_path

    assert_redirected_to root_path
    assert_equal "❌ Acesso negado. O painel técnico exige cargo máximo.", flash[:alert]
  end

  test "ações administrativas de acesso da guilda e usuário funcionam" do
    User.stubs(:check_guild_role_access).returns(true)
    checked_user = users(:five)
    checked_user.update!(has_guild_access: false)

    assert_difference -> { AuditLog.where(action: "guild_access_synced").count }, 1 do
      post sync_access_admin_guild_path(guilds(:one))
    end
    assert_redirected_to admin_guild_path(guilds(:one))

    assert_difference -> { AuditLog.where(action: "user_access_checked").count }, 1 do
      post check_access_admin_user_path(checked_user)
    end
    assert_redirected_to admin_user_path(checked_user)
    assert checked_user.reload.has_guild_access
  end

  test "ações administrativas revisam pedidos e submissões de missão" do
    approved_request = create_mission_request!("Pedido AA aprovado", users(:five))
    rejected_request = create_mission_request!("Pedido AA rejeitado", users(:six))

    post approve_admin_mission_request_path(approved_request), params: { admin_notes: "ok" }
    assert_redirected_to admin_mission_request_path(approved_request)
    assert_equal "approved", approved_request.reload.status

    post reject_admin_mission_request_path(rejected_request), params: { admin_notes: "fora do escopo" }
    assert_redirected_to admin_mission_request_path(rejected_request)
    assert_equal "rejected", rejected_request.reload.status

    rewarded_submission = create_mission_submission!(users(:five), "2026-W90", 1)
    rejected_submission = create_mission_submission!(users(:six), "2026-W90", 1)

    post approve_admin_mission_submission_path(rewarded_submission), params: { review_notes: "aprovada" }
    assert_redirected_to admin_mission_submission_path(rewarded_submission)
    assert_equal "approved", rewarded_submission.reload.status

    post reward_admin_mission_submission_path(rewarded_submission)
    assert_redirected_to admin_mission_submission_path(rewarded_submission)
    assert_equal "rewarded", rewarded_submission.reload.status

    post reject_admin_mission_submission_path(rejected_submission), params: { review_notes: "insuficiente" }
    assert_redirected_to admin_mission_submission_path(rejected_submission)
    assert_equal "rejected", rejected_submission.reload.status
  end

  test "ações administrativas atendem pedidos da loja e revogam certificado" do
    buyer = users(:five)
    buyer.update!(currency_balance: 300)
    fulfilled_order = checkout_order!(buyer, "Entrega ActiveAdmin")
    rejected_order = checkout_order!(buyer, "Rejeição ActiveAdmin")
    canceled_order = checkout_order!(buyer, "Cancelamento ActiveAdmin")

    post fulfill_admin_store_order_path(fulfilled_order)
    assert_redirected_to admin_store_order_path(fulfilled_order)
    assert_equal "fulfilled", fulfilled_order.reload.status

    post reject_admin_store_order_path(rejected_order)
    assert_redirected_to admin_store_order_path(rejected_order)
    assert_equal "rejected", rejected_order.reload.status

    post cancel_admin_store_order_path(canceled_order)
    assert_redirected_to admin_store_order_path(canceled_order)
    assert_equal "canceled", canceled_order.reload.status

    user_certificate = UserCertificate.create!(
      user: users(:five),
      certificate: certificates(:one),
      granted_by: @admin
    )

    post revoke_admin_user_certificate_path(user_certificate)
    assert_redirected_to admin_user_certificate_path(user_certificate)
    assert_equal "revoked", user_certificate.reload.status
  end

  test "CRUD básico de item da loja pelo ActiveAdmin audita alterações" do
    assert_difference("StoreItem.count", 1) do
      assert_difference -> { AuditLog.where(action: "store_item_created").count }, 1 do
        post admin_store_items_path, params: {
          store_item: store_item_params(name: "Item ActiveAdmin")
        }
      end
    end

    item = StoreItem.order(:created_at).last
    assert_redirected_to admin_store_item_path(item)

    assert_difference -> { AuditLog.where(action: "store_item_updated").count }, 1 do
      patch admin_store_item_path(item), params: {
        store_item: store_item_params(name: "Item ActiveAdmin Atualizado", price: 35)
      }
    end
    assert_redirected_to admin_store_item_path(item)
    assert_equal "Item ActiveAdmin Atualizado", item.reload.name

    assert_difference("StoreItem.count", -1) do
      assert_difference -> { AuditLog.where(action: "store_item_destroyed").count }, 1 do
        delete admin_store_item_path(item)
      end
    end
    assert_redirected_to admin_store_items_path
  end

  private

  def readable_resources
    store_item = StoreItem.create!(guild: guilds(:one), name: "Item AA leitura", price: 10, stock_quantity: 1)
    store_order = StoreOrder.checkout!(user: users(:five), store_item: store_item)

    [
      { index_path: :admin_root_path, show_path: :admin_root_path, record: nil, index_text: "Estatísticas Gerais", show_text: "Guilds Recentes" },
      { index_path: :admin_guilds_path, show_path: :admin_guild_path, record: guilds(:one), index_text: "Guilda dos Guerreiros", show_text: "Estatísticas" },
      { index_path: :admin_users_path, show_path: :admin_user_path, record: users(:one), index_text: "warrior_one", show_text: "Cargos" },
      { index_path: :admin_roles_path, show_path: :admin_role_path, record: roles(:one), index_text: "Cargo Máximo", show_text: "Usuários com este Cargo" },
      { index_path: :admin_permission_groups_path, show_path: :admin_permission_group_path, record: permission_groups(:one_admin), index_text: "Administração", show_text: "Roles do Discord vinculadas" },
      { index_path: :admin_missions_path, show_path: :admin_mission_path, record: missions(:one), index_text: "Missão Semanal de Dungeons", show_text: "Submissões recentes" },
      { index_path: :admin_mission_submissions_path, show_path: :admin_mission_submission_path, record: mission_submissions(:one), index_text: "2026-W03", show_text: "Answers Json" },
      { index_path: :admin_mission_requests_path, show_path: :admin_mission_request_path, record: create_mission_request!("Pedido AA leitura", users(:five)), index_text: "Pedido AA leitura", show_text: "Metadata" },
      { index_path: :admin_achievements_path, show_path: :admin_achievement_path, record: achievements(:one), index_text: "Primeira Raid", show_text: "Criteria" },
      { index_path: :admin_user_achievements_path, show_path: :admin_user_achievement_path, record: user_achievements(:one), index_text: "Primeira Raid", show_text: "User Achievement" },
      { index_path: :admin_certificates_path, show_path: :admin_certificate_path, record: certificates(:one), index_text: "Líder de Raid", show_text: "raid_leader" },
      { index_path: :admin_user_certificates_path, show_path: :admin_user_certificate_path, record: user_certificates(:one), index_text: "Líder de Raid", show_text: "Granted By" },
      { index_path: :admin_rankings_path, show_path: :admin_ranking_path, record: rankings(:user_xp), index_text: "XP dos membros", show_text: "XP" },
      { index_path: :admin_squads_path, show_path: :admin_squad_path, record: squads(:one), index_text: "Esquadrão Alpha", show_text: "Membros" },
      { index_path: :admin_store_items_path, show_path: :admin_store_item_path, record: store_item, index_text: "Item AA leitura", show_text: "Pedidos recentes" },
      { index_path: :admin_store_orders_path, show_path: :admin_store_order_path, record: store_order, index_text: "pending", show_text: "Price Paid" },
      { index_path: :admin_audit_logs_path, show_path: :admin_audit_log_path, record: audit_logs(:one), index_text: "create_squad", show_text: "Metadata" }
    ]
  end

  def form_resources
    store_item = StoreItem.create!(guild: guilds(:one), name: "Item AA form", price: 10)
    store_order = StoreOrder.create!(user: users(:five), store_item: store_item)

    [
      { new_path: :new_admin_guild_path, edit_path: :edit_admin_guild_path, record: guilds(:one), form_text: "Informações Básicas" },
      { new_path: :new_admin_user_path, edit_path: :edit_admin_user_path, record: users(:one), form_text: "Informações do Discord" },
      { new_path: :new_admin_role_path, edit_path: :edit_admin_role_path, record: roles(:one), form_text: "Gerenciado pelo App" },
      { new_path: :new_admin_permission_group_path, edit_path: :edit_admin_permission_group_path, record: permission_groups(:one_admin), form_text: "Grupo de Permissões" },
      { new_path: :new_admin_mission_path, edit_path: :edit_admin_mission_path, record: missions(:one), form_text: "Missão" },
      { new_path: :new_admin_mission_submission_path, edit_path: :edit_admin_mission_submission_path, record: mission_submissions(:one), form_text: "Week reference" },
      { new_path: :new_admin_mission_request_path, edit_path: :edit_admin_mission_request_path, record: create_mission_request!("Pedido AA form", users(:five)), form_text: "Title" },
      { new_path: :new_admin_achievement_path, edit_path: :edit_admin_achievement_path, record: achievements(:one), form_text: "Conquista" },
      { new_path: :new_admin_user_achievement_path, edit_path: :edit_admin_user_achievement_path, record: user_achievements(:one), form_text: "Concessão de conquista" },
      { new_path: :new_admin_certificate_path, edit_path: :edit_admin_certificate_path, record: certificates(:one), form_text: "Certificado" },
      { new_path: :new_admin_user_certificate_path, edit_path: :edit_admin_user_certificate_path, record: user_certificates(:one), form_text: "Concessão de certificado" },
      { new_path: :new_admin_ranking_path, edit_path: :edit_admin_ranking_path, record: rankings(:user_xp), form_text: "Ranking" },
      { new_path: :new_admin_squad_path, edit_path: :edit_admin_squad_path, record: squads(:one), form_text: "TAG do squad" },
      { new_path: :new_admin_store_item_path, edit_path: :edit_admin_store_item_path, record: store_item, form_text: "Item da loja" },
      { new_path: nil, edit_path: :edit_admin_store_order_path, record: store_order, form_text: "Pedido da loja" }
    ]
  end

  def admin_path_for(helper_name, record = nil)
    record ? public_send(helper_name, record) : public_send(helper_name)
  end

  def create_mission_request!(title, requester)
    MissionRequest.create!(
      guild: requester.guild,
      requester: requester,
      title: title,
      description: "Fluxo básico ActiveAdmin"
    )
  end

  def create_mission_submission!(user, week_reference, period_sequence)
    MissionSubmission.create!(
      mission: missions(:one),
      user: user,
      week_reference: week_reference,
      period_sequence: period_sequence,
      quantity: 1
    )
  end

  def checkout_order!(buyer, item_name)
    StoreOrder.checkout!(
      user: buyer,
      store_item: StoreItem.create!(
        guild: buyer.guild,
        name: item_name,
        price: 10,
        stock_quantity: 1
      )
    )
  end

  def store_item_params(name:, price: 20)
    {
      guild_id: guilds(:one).id,
      name: name,
      description: "Criado pelo teste de fluxo ActiveAdmin",
      category: "Teste",
      price: price,
      stock_quantity: 2,
      status: "active",
      fulfillment_type: "manual"
    }
  end
end
