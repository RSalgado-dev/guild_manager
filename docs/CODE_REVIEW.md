# Revisão de Código — Guild Manager (TCC)

**Data:** 2026-05-02
**Escopo:** Rails 8.1, Ruby 4.0.0, integração Discord OAuth + Bot, ActiveAdmin, Hotwire, Tailwind, Solid Queue/Cache/Cable.
**Base de comparação:** `idea.md` (especificação original) e `db/schema.rb`.
**Arquivos auditados:** `app/models`, `app/controllers`, `app/services`, `app/jobs`, `test/`, `config/`.

---

## 1. Riscos críticos (corrigir antes da apresentação)

### 1.1 Segurança

- **Token Discord em texto puro no banco**
  - `db/schema.rb:598-602`, `app/models/user.rb:340-354`.
  - `users.discord_access_token` e `discord_refresh_token` persistidos sem criptografia.
  - Vazamento de banco = vazamento de tokens ativos.
  - **Ação:** `encrypts :discord_access_token, deterministic: false` (Active Record Encryption nativo do Rails 8) ou descartar o access token e regenerar via refresh token quando necessário.

- **Logs vazando token e dados sensíveis**
  - `app/controllers/sessions_controller.rb:19-25` logam `Access token (10 primeiros chars)`, `Guilds data`, `raw_info`.
  - `filter_parameter_logging.rb` filtra params, mas `Rails.logger.info` direto não passa pelo filtro.
  - **Ação:** remover ou ocultar atrás de flag explícita (`ENV["DISCORD_DEBUG"]`), nunca logar token nem nos primeiros chars.

- **Sem refresh do token Discord**
  - `User#sync_discord_roles_if_stale!` (`app/models/user.rb:400-405`) usa `discord_access_token` cru.
  - O campo `discord_token_expires_at` existe mas não é checado.
  - **Ação:** implementar troca pelo `refresh_token` quando `expires_at < Time.current`.

- **Fallback "permissivo" perigoso em produção**
  - `User.check_guild_role_access` (`app/models/user.rb:436, 446`) retorna `true` se não houver `bot_token` ou se a API do Discord falhar.
  - Em produção isso libera acesso geral a partir do primeiro hiccup do Discord.
  - **Ação:** *fail-closed* em produção (negar acesso). Manter modo permissivo apenas em `Rails.env.development?`.

- **OAuth state não validado explicitamente**
  - `sessions_controller.rb:8-9` confia no `omniauth.auth` sem validar `omniauth.state` por conta própria.
  - OmniAuth gera state, mas convém garantir `provider_ignores_state: false` na config e ler `request.env["omniauth.state"]` para auditar.

- **Mass assignment de `leader_id` em squads**
  - `access/squads_controller.rb` aceita `leader_id` no `permit` da criação. Validação de "líder pertence à guild" está em modelo, mas o endpoint permite que um usuário promova outro a líder se passar o id.
  - **Ação:** forçar `leader: current_user` no controller ou bloquear `leader_id` no strong params.

- **`script/create_first_admin.rb` cria admin com `discord_id: "000000000000000000"` e `is_admin: true`**
  - Se rodar em produção por engano, vira admin permanente acessível via `/dev/admin_login`.
  - **Ação:** `raise unless Rails.env.development?` no início do script.

- **`dev_sessions` controller existe sem cinto-e-suspensório**
  - Rotas estão protegidas por `if Rails.env.development?` em `routes.rb:93`. OK, mas o controller continua carregado.
  - **Ação:** adicionar `before_action { head :forbidden unless Rails.env.development? }` no controller.

### 1.2 Concorrência / consistência financeira

- **`User#apply_currency!` não tem lock**
  - `app/models/user.rb:264-279`: lê `currency_balance`, soma `delta`, `update!` sem lock.
  - Duas requisições concorrentes do mesmo usuário causam *lost update* e podem deixar saldo negativo.
  - A validação `numericality >= 0` só dispara *após* o cálculo; não previne corrida real.
  - **Ação:** `with_lock { ... }` + validar `new_balance >= 0` explicitamente antes do `update!`.

- **`User#apply_xp!` lockeia depois do read**
  - `app/models/user.rb:281-286`: `lock!` é chamado, mas `xp_points + delta` (linha 284) usa o atributo já lido em memória, anterior ao lock real.
  - **Ação:** `with_lock { reload; update!(xp_points: xp_points + delta) }` ou `update_counters`.

- **Nested transaction sem `requires_new: true`**
  - `StoreOrder.checkout!` abre transação e chama `apply_currency!`, que abre outra.
  - Sem `requires_new`, falhas internas não fazem rollback do escopo externo no PostgreSQL.
  - **Ação:** `transaction(requires_new: true)` na transação interna ou achatar para uma única transação.

- **Recompensa duplicada em `AutomaticMissionEvaluator`**
  - `app/services/automatic_mission_evaluator.rb:29-59`: dois jobs simultâneos passam a mesma checagem `submissions_count_for < max`, ambos tentam `create!`, um vence pelo unique index, o outro é silenciosamente engolido por `rescue`.
  - **Ação:** envolver em `mission.with_lock { ... }` e tratar `RecordNotUnique` explicitamente (não silenciar).

### 1.3 Integridade do schema

- **`certificates.role_id` é nullable**
  - `db/schema.rb:107`, `Certificate#belongs_to :role, optional: true`.
  - **`idea.md` linha 19** diz literalmente: "eles devem sempre estarem atrelados a um cargo cosmético".
  - **Ação:** migration `change_column_null :certificates, :role_id, false` e remover `optional: true`.

- **Fixture `users.yml` com `has_guild_access` duplicado**
  - `test/fixtures/users.yml:16-17`. YAML aceita silenciosamente.
  - **Ação:** remover linha duplicada.

- **`mission_submission` sem validação cross-guild**
  - Não valida que `mission.guild == user.guild`. Possível submissão para missão de guild diferente via formulário malformado.
  - **Ação:** `validate :mission_belongs_to_user_guild`.

---

## 2. Divergências com `idea.md`

| `idea.md` | Estado atual | Avaliação |
|---|---|---|
| Cargos: base / cosmético / especial / administrativo / **máximo** | `Role.category` cobre 4. "Máximo" representado por `PermissionGroup.all_access`, sem amarração 1-1 com um Role específico | **Divergência conceitual.** Funcional, mas pouco clara para a banca |
| Permissões granulares por cargo administrativo | Implementado via `PermissionGroup` + `permission_group_roles` | **OK** |
| `User#is_admin` boolean | Coexiste com `PermissionGroup.all_access` — duas formas de "ser admin" | **Redundância.** Migrar para um único caminho (PermissionGroup) e deixar `is_admin` apenas como flag de bootstrap |
| Eventos: matriz **2×3** (respondeu/não respondeu × presente/justificada/falta) com %s 100/0/20/50/0/25 | Implementado via `source_block` (3 estados) × `final_status` (3 estados) com matriz `REWARD_RULES` em `app/models/event_participation.rb:2-18`. Cobertura: confirmed×{participated=1.0, justified=0.0, absent=0.0}, justified(=declined+justification)×{participated=0.5, justified=0.2, absent=0.0}, absent(=sem resposta)×{participated=0.25, …} | **Funcionalmente equivalente.** Modelagem é menos óbvia que a matriz literal mas atinge os 6 valores. **Documentar mapping no relatório do TCC** |
| Eventos: usuário precisa dar **motivo** ao recusar | Campo `justification` existe; `events_controller#respond` não impõe presença obrigatória condicional | **Verificar/forçar validação** quando `rsvp_status=declined` |
| Missões automáticas (plataforma) vs manuais (com print) | `mission_type` (`manual`/`automatic`) e `reward_mode` (`fixed`/`per_unit`). `AutomaticMissionEvaluator` só implementa **1 trigger** (`primary_character_updated`) | **Parcial.** Expandir para ≥3 triggers ou documentar como ponto de extensão |
| Conquistas: catálogo público (preexistente) vs individual (não listada) | `achievement_type` + `visibility` + scope `catalog_visible` + validação que individual não tem `reward_profile_name_color` | **OK, bem implementado** |
| Certificados sempre atrelados a cargo cosmético | `Certificate.role_id` nullable | **DIVERGÊNCIA** (ver §1.3) |
| Sync Discord ↔ App **constante e sem sobreposição** | Polling a cada 5/10/15 min via Solid Queue. Sem webhook e sem `last_changed_at` por origem para arbitrar conflito | **Divergência substancial.** "Constante" + "sem sobreposição" exige webhook ou política explícita de prioridade entre origens |
| Membro sem cargo base → tela "sem acesso" + orientação a procurar recrutamento | `restricted_access_path` redireciona para `access/dashboard#restricted` | Verificar se a view `access/dashboard/restricted.html.erb` reflete a orientação a Discord/admins do `idea.md` |
| Loja: gastar moedas em itens cadastrados | Implementado com débito + reembolso atômicos | **OK** |
| Ranking: público + escopo configurável (users/squads) | `rankings.ranking_scope`, `metric`, `entries_limit` | **OK** |
| Mission Request (cargos especiais) → vira missão após aprovação | `MissionRequest` + verificação `category: "special"` no controller | **OK** |
| Squads: revisão de imagem **e** nome/sigla/descrição (sem abuso) | Dois fluxos separados (`emblem_status` + `pending_profile_changes`) | **Divergência leve de UX.** Funcional, mas quebra a aprovação em duas etapas distintas |

---

## 3. Bugs e más práticas (não bloqueantes mas importantes)

- **Condição morta em `access/profiles_controller#update`**
  `if user_profile_params[:email].present? && user_profile_params[:email].blank?` — sempre falsa. Validação de email nunca dispara.

- **N+1 em `events_controller#show`**
  Filtra `participations` em memória com `.select { |p| p.source_block == :confirmed }`. Mover para SQL com `.where(rsvp_status: :confirmed)`.

- **`AccessController#refresh_discord_roles_cache`**
  Chama `sync_discord_roles_if_stale!` em toda action de admin → 1 request HTTP ao Discord por clique, com `PERMISSION_CHECK_SYNC_MAX_AGE = 30.seconds`. Considerar enfileirar a sync (já existe job) e não bloquear o request.

- **Sem paginação**
  `events_controller#index`, `achievements#index`, `rankings#index`, `audit_logs` carregam tudo. Adicionar `kaminari` ou `pagy`.

- **`CurrencyTransaction#reason`**
  `reason_type.constantize.find_by(...)` sem rescue de `NameError`. Validar contra allowlist de tipos.

- **`reconcile_discord_managed_roles` a cada 5 min** (`config/recurring.yml:22-24`)
  Para 100 usuários ≈ 1.200 calls/h ao Discord, próximo do limite. Adicionar jitter no schedule e/ou só reconciliar usuários com mudança recente.

- **`fetch_user_guilds`** (`user.rb:375-385`)
  Loga `access_token[0..10]` — mesmo 10 chars são identificáveis em log compartilhado. Trocar por `present?` boolean.

- **`User#permission_groups`** (`user.rb:161-163`)
  Retorna grupos de qualquer guild que o usuário tenha role. Como `User` é single-tenant, OK hoje; se virar multi-guild, precisa filtrar.

- **Squad: `emblem_uploaded_by_id`** declarado como `integer` no schema, sem foreign key explícita coerente com as demais. Verificar coerência das migrations.

- **Sem retry/backoff em chamadas Discord**
  `app/services/discord_api_client.rb` retorna `false`/`nil` em falhas (incluindo 429). Implementar `retry_on Net::OpenTimeout, ...` no job ou exponential backoff no client.

- **`AuditLog` pode receber metadata sensível** sem filtro
  `app/services/discord_member_role_sync.rb` cria `AuditLog` com payload do Discord. Verificar se nenhum token/email cai no `metadata`.

---

## 4. O que está bem feito (registrar no TCC)

- **AuditLog abrangente** — eventos, RSVP, store, login, mission submission. Excelente narrativa de "rastreabilidade".
- **Permissionamento granular** — `PermissionGroup` com 14+ chaves de permissão é uma das peças mais maduras do projeto.
- **Recompensas modeladas como dados** — `EventParticipation::REWARD_RULES`, `Mission#reward_mode` (fixed/per_unit). Fácil de explicar e de evoluir.
- **Multi-tenant disciplinado** — quase todo `find` parte de `@guild.<assoc>` (proteção IDOR) e validações `*_belongs_to_guild`.
- **Stack Solid (Queue/Cache/Cable)** — uso da pilha Rails 8 nativa, sem Redis. Bom argumento de simplicidade operacional.
- **WebMock + stubs Discord centralizados** em `test/test_helper.rb:25-43` — testes desacoplados da rede.
- **Cobertura de testes razoável** — fluxos críticos cobertos: checkout/refund, RSVP, mission reward, role sync, permission_group enforcement.
- **Validações de coerência multi-tenant** em `PermissionGroupRole#same_guild`, `Squad#leader_must_belong_to_guild`, `Certificate#role_must_belong_to_guild`.

---

## 5. Sugestões de incremento para o TCC

Em ordem de impacto/visibilidade na banca:

1. **Webhook do Discord (Bot Gateway)** substituindo polling em pelo menos um caminho — atende literalmente o "sincronização constante" do `idea.md` e dá um diferencial técnico relevante. Mesmo um único endpoint que escuta `GUILD_MEMBER_UPDATE` e enfileira reconciliação já é suficiente.
2. **Notificações in-app** (Turbo Streams + Solid Cable) para: convite de squad, evento próximo, missão revisada, pedido da loja atendido. *Killer feature* de gamificação usando stack Rails 8 nativa.
3. **Dashboard de métricas para admin** (eventos por mês, conquistas mais raras, top XP, fila de revisões pendentes). Ótimo screenshot para o relatório.
4. **Mais triggers de missão automática** — `first_login_of_week`, `event_attended_count`, `mission_completed_streak`. Demonstra extensibilidade e fortalece a seção de gamificação.
5. **Página pública de rankings** (sem login, read-only) — `idea.md` permite ("seção dedicada a ranks"). Bom para vitrine da guild.
6. **Motor de critérios para conquistas em DSL/JSON** — hoje `criteria` é `jsonb` mas não há motor de avaliação. Mesmo um `AchievementEvaluator` simples (4-5 critérios) já vira capítulo do TCC.
7. **Verificação de certificados via QR/short link** — alinhado com a frase "certificados como guia na visualização" no `idea.md`.
8. **Trocar `is_admin` por `bootstrap_admin`** com migration de dados para `PermissionGroup#all_access` — limpa a ambiguidade sem perder retrocompatibilidade.
9. **Encriptar `discord_*_token`** com Active Record Encryption (1 linha + migration). Citável como "boas práticas de segurança".
10. **Internacionalização (I18n)** — UI mistura português e mensagens cruas. Centralizar em `config/locales/pt-BR.yml` deixa o capítulo de qualidade mais sólido.
11. **Testes de concorrência** — um teste com `Concurrent::Promises` ou threads para `apply_currency!` mostra maturidade.
12. **Healthcheck composto** — `/up` já existe; adicionar versão que valida DB + Solid Queue + Discord API ping.

---

## 6. Top 10 acionáveis para fechar o MVP

1. Encriptar `discord_access_token`/`refresh_token` com Active Record Encryption.
2. Remover/condicionar logs sensíveis em `sessions_controller.rb:11-27`.
3. Adicionar `lock!` correto em `User#apply_currency!` e `apply_xp!`.
4. `Certificate.role_id` → `null: false` (migration + validação `presence: true`).
5. Bug de email em `profiles_controller#update` (linha 18: `present? && blank?`).
6. Validar `justification` obrigatória quando `rsvp_status=declined`.
7. Implementar refresh de token Discord ao expirar.
8. `AutomaticMissionEvaluator` em `with_lock` + tratar `RecordNotUnique` corretamente.
9. Trocar fallback "permissivo" de `check_guild_role_access` em produção (fail-closed).
10. Remover `has_guild_access` duplicado em `test/fixtures/users.yml`.

---

## Apêndice A — Pontos de inspeção rápida (checklist)

- [ ] `config/initializers/omniauth.rb` — confirmar `provider_ignores_state: false`.
- [ ] `app/views/access/dashboard/restricted.html.erb` — texto cita Discord e admin?
- [ ] `app/controllers/access/events_controller.rb#response_params` — `justification` obrigatória se `declined`?
- [ ] `app/services/discord_api_client.rb` — tratamento de 429/503 com retry?
- [ ] `app/admin/*.rb` — toda action admin checa `has_permission?` ou só `is_admin`?
- [ ] `db/seeds.rb` — vazio. Definir seed mínimo (guild, roles, permission groups, achievements de exemplo) para reprodutibilidade da banca.
- [ ] Fixtures sincronizadas com schema atual (após corrigir `users.yml`).
- [ ] `discord_token_expires_at` consultado em algum ponto antes de chamar a API?
