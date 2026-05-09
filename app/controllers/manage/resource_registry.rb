# frozen_string_literal: true

module Manage
  module ResourceRegistry
    CONFIGS = {
      "guild" => {
        label: "Guilda",
        model: Guild,
        permission: :manage_guild_settings,
        singleton: true,
        fields: [
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :discord_guild_id, label: "Discord Guild ID", type: :string },
          { name: :discord_name, label: "Nome no Discord", type: :string },
          { name: :required_discord_role_id, label: "ID do cargo base", type: :string },
          { name: :required_discord_role_name, label: "Nome do cargo base", type: :string },
          { name: :character_template, label: "Template de personagem", type: :json }
        ],
        actions: [ "sync_access" ]
      },
      "users" => {
        label: "Membros",
        model: User,
        permission: :manage_members,
        fields: [
          { name: :discord_id, label: "Discord ID", type: :string },
          { name: :discord_username, label: "Usuário Discord", type: :string },
          { name: :discord_nickname, label: "Apelido", type: :string },
          { name: :email, label: "Email", type: :string },
          { name: :has_guild_access, label: "Acesso à guilda", type: :boolean },
          { name: :xp_points, label: "XP", type: :integer },
          { name: :currency_balance, label: "Moedas", type: :integer },
          { name: :squad_id, label: "Squad", type: :select, collection: :squads, optional: true },
          { name: :role_ids, label: "Cargos", type: :multiselect, collection: :roles }
        ],
        actions: [ "check_access" ]
      },
      "roles" => {
        label: "Cargos",
        model: Role,
        permission: :manage_roles,
        fields: [
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :category, label: "Categoria", type: :select, collection: :role_categories },
          { name: :discord_role_id, label: "Discord Role ID", type: :string },
          { name: :managed_by_app, label: "Gerenciado pelo app", type: :boolean },
          { name: :is_admin, label: "Flag admin legado", type: :boolean }
        ]
      },
      "permission_groups" => {
        label: "Grupos de Permissão",
        model: PermissionGroup,
        permission: :manage_administrative_roles,
        fields: [
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :all_access, label: "Acesso total", type: :boolean },
          { name: :permissions, label: "Permissões", type: :multiselect, collection: :permissions },
          { name: :role_ids, label: "Cargos vinculados", type: :multiselect, collection: :roles }
        ]
      },
      "events" => {
        label: "Eventos",
        model: Event,
        permission: :manage_events,
        fields: [
          { name: :title, label: "Título", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :event_type, label: "Tipo", type: :string },
          { name: :starts_at, label: "Início", type: :datetime },
          { name: :ends_at, label: "Fim", type: :datetime },
          { name: :recurrence, label: "Recorrência", type: :select, collection: :event_recurrences },
          { name: :status, label: "Status", type: :select, collection: :event_statuses },
          { name: :reward_xp, label: "XP", type: :integer },
          { name: :reward_currency, label: "Moedas", type: :integer }
        ],
        actions: [ "complete_default" ]
      },
      "missions" => {
        label: "Missões",
        model: Mission,
        permission: :manage_missions,
        fields: [
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :mission_type, label: "Tipo", type: :select, collection: :mission_types },
          { name: :frequency, label: "Frequência", type: :select, collection: :mission_frequencies },
          { name: :reward_mode, label: "Modo de recompensa", type: :select, collection: :mission_reward_modes },
          { name: :reward_xp, label: "XP fixo", type: :integer },
          { name: :reward_currency, label: "Moedas fixas", type: :integer },
          { name: :reward_xp_per_unit, label: "XP por unidade", type: :integer },
          { name: :reward_currency_per_unit, label: "Moedas por unidade", type: :integer },
          { name: :max_submissions_per_period, label: "Limite por período", type: :integer },
          { name: :metadata_json, label: "Metadados", type: :json },
          { name: :active, label: "Ativa", type: :boolean }
        ]
      },
      "mission_submissions" => {
        label: "Submissões",
        model: MissionSubmission,
        permission: :review_mission_submissions,
        fields: [
          { name: :mission_id, label: "Missão", type: :select, collection: :missions },
          { name: :user_id, label: "Usuário", type: :select, collection: :users },
          { name: :week_reference, label: "Período", type: :string },
          { name: :period_sequence, label: "Sequência", type: :integer },
          { name: :quantity, label: "Quantidade", type: :integer },
          { name: :status, label: "Status", type: :select, collection: :mission_submission_statuses },
          { name: :review_notes, label: "Notas", type: :text },
          { name: :reward_xp_awarded, label: "XP concedido", type: :integer },
          { name: :reward_currency_awarded, label: "Moedas concedidas", type: :integer }
        ],
        actions: [ "approve", "reject", "reward" ]
      },
      "mission_requests" => {
        label: "Pedidos de Missão",
        model: MissionRequest,
        permission: :manage_missions,
        fields: [
          { name: :requester_id, label: "Solicitante", type: :select, collection: :users },
          { name: :title, label: "Título", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :status, label: "Status", type: :select, collection: :mission_request_statuses },
          { name: :admin_notes, label: "Notas admin", type: :text }
        ],
        actions: [ "approve", "reject" ]
      },
      "achievements" => {
        label: "Conquistas",
        model: Achievement,
        permission: :manage_achievements,
        fields: [
          { name: :code, label: "Código", type: :string },
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :category, label: "Categoria", type: :string },
          { name: :achievement_type, label: "Tipo", type: :select, collection: :achievement_types },
          { name: :visibility, label: "Visibilidade", type: :select, collection: :achievement_visibilities },
          { name: :criteria_json, label: "Critérios", type: :json },
          { name: :reward_xp, label: "XP", type: :integer },
          { name: :reward_currency, label: "Moedas", type: :integer },
          { name: :reward_profile_name_color, label: "Cor do perfil", type: :string },
          { name: :active, label: "Ativa", type: :boolean }
        ]
      },
      "user_achievements" => {
        label: "Concessões de Conquista",
        model: UserAchievement,
        permission: :grant_achievements,
        fields: [
          { name: :user_id, label: "Usuário", type: :select, collection: :users },
          { name: :achievement_id, label: "Conquista", type: :select, collection: :achievements },
          { name: :earned_at, label: "Data", type: :datetime }
        ]
      },
      "certificates" => {
        label: "Certificados",
        model: Certificate,
        permission: :manage_certificates,
        fields: [
          { name: :code, label: "Código", type: :string },
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :category, label: "Categoria", type: :string },
          { name: :icon_url, label: "Ícone", type: :string },
          { name: :role_id, label: "Cargo cosmético", type: :select, collection: :cosmetic_roles },
          { name: :active, label: "Ativo", type: :boolean }
        ]
      },
      "user_certificates" => {
        label: "Concessões de Certificado",
        model: UserCertificate,
        permission: :grant_certificates,
        fields: [
          { name: :user_id, label: "Usuário", type: :select, collection: :users },
          { name: :certificate_id, label: "Certificado", type: :select, collection: :certificates },
          { name: :granted_at, label: "Concedido em", type: :datetime },
          { name: :expires_at, label: "Expira em", type: :datetime },
          { name: :status, label: "Status", type: :select, collection: :user_certificate_statuses }
        ],
        actions: [ "revoke" ]
      },
      "rankings" => {
        label: "Rankings",
        model: Ranking,
        permission: :manage_rankings,
        fields: [
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :ranking_scope, label: "Escopo", type: :select, collection: :ranking_scopes },
          { name: :metric, label: "Métrica", type: :select, collection: :ranking_metrics },
          { name: :sort_direction, label: "Ordenação", type: :select, collection: :ranking_sort_directions },
          { name: :entries_limit, label: "Limite", type: :integer },
          { name: :position, label: "Posição", type: :integer },
          { name: :active, label: "Ativo", type: :boolean }
        ]
      },
      "store_items" => {
        label: "Itens da Loja",
        model: StoreItem,
        permission: :manage_store,
        fields: [
          { name: :name, label: "Nome", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :category, label: "Categoria", type: :string },
          { name: :price, label: "Preço", type: :integer },
          { name: :stock_quantity, label: "Estoque", type: :integer },
          { name: :status, label: "Status", type: :select, collection: :store_item_statuses },
          { name: :fulfillment_type, label: "Entrega", type: :select, collection: :store_fulfillment_types }
        ]
      },
      "store_orders" => {
        label: "Pedidos da Loja",
        model: StoreOrder,
        permission: :fulfill_store_orders,
        no_create: true,
        fields: [
          { name: :user_id, label: "Comprador", type: :select, collection: :users, readonly: true },
          { name: :store_item_id, label: "Item", type: :select, collection: :store_items, readonly: true },
          { name: :status, label: "Status", type: :select, collection: :store_order_statuses, readonly: true },
          { name: :price_paid, label: "Preço pago", type: :integer, readonly: true },
          { name: :admin_notes, label: "Notas admin", type: :text }
        ],
        actions: [ "fulfill", "reject", "cancel" ]
      },
      "squads" => {
        label: "Squads",
        model: Squad,
        permission: :manage_members,
        fields: [
          { name: :name, label: "Nome", type: :string },
          { name: :tag, label: "Tag", type: :string },
          { name: :description, label: "Descrição", type: :text },
          { name: :leader_id, label: "Líder", type: :select, collection: :users },
          { name: :profile_change_status, label: "Revisão", type: :select, collection: :squad_profile_statuses }
        ],
        actions: [ "approve_profile_change", "reject_profile_change" ]
      },
      "audit_logs" => {
        label: "Auditoria",
        model: AuditLog,
        permission: :view_audit_logs,
        readonly: true,
        fields: [
          { name: :action, label: "Ação", type: :string },
          { name: :user_id, label: "Usuário", type: :select, collection: :users },
          { name: :entity_type, label: "Entidade", type: :string },
          { name: :entity_id, label: "ID da entidade", type: :integer },
          { name: :metadata, label: "Metadados", type: :json }
        ]
      }
    }.freeze

    def self.configs_for(user)
      CONFIGS.select { |_key, config| user.has_permission?(config[:permission]) }
    end
  end
end
