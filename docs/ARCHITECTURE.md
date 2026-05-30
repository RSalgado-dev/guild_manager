# Arquitetura do Código

## Entrada HTTP

As rotas ficam em `config/routes.rb`.

- `/auth/discord/callback` e `/auth/failure`: fluxo OmniAuth em `SessionsController`.
- `/dashboard`, `/profile`, `/events`, `/missions`, `/achievements`, `/certificates`, `/rankings`, `/store`, `/squads`: área de membros em `app/controllers/access`.
- `/manage`: gestão operacional em `app/controllers/manage`.
- `/admin`: ActiveAdmin, carregado por `ActiveAdmin.routes(self)`.
- `/public/guilds/:guild_id/rankings`: rankings públicos.
- `/webhooks/discord/member_update`: webhook interno protegido por segredo.
- `/up` e `/up/full`: health checks.

## Autenticação e Acesso

`config/initializers/omniauth.rb` configura OAuth Discord com escopos `identify guilds email`.

`SessionsController#create` cria ou atualiza o usuário via `User.find_or_create_from_discord`, registra auditoria e redireciona conforme `has_guild_access`.

`ApplicationController` expõe helpers de sessão e autorização:

- `current_user`
- `logged_in?`
- `has_guild_access?`
- `has_permission?`
- `admin_panel_access?`
- `manage_area_access?`

`AccessController` é a base da área autenticada e atualiza roles Discord em cache antes das telas internas.

## Domínio Principal

- `Guild`: representa uma guilda local vinculada a um servidor Discord. Centraliza usuários, cargos, squads, eventos, missões, conquistas, certificados, rankings, loja e configurações de acesso.
- `User`: usuário Discord autenticado. Guarda XP, moeda, acesso à guilda, tokens criptografados, roles, permissões, conquistas, certificados, personagens e pedidos.
- `Role`: cargo importado ou gerenciado pelo app. Categorias incluem cargos base, cosméticos, especiais, administrativos e máximo.
- `PermissionGroup`: liga roles a permissões granulares. `all_access` concede o conjunto completo.
- `AuditLog`: trilha de auditoria com sanitização de metadados sensíveis.

## Módulos de Membro

- Perfil e personagens: `ProfilesController`, `CharactersController`, `GameCharacter`.
- Squads: `SquadsController`, `SquadInvitationsController`, `Squad`, `SquadInvitation`.
- Eventos: `EventsController`, `Event`, `EventParticipation`.
- Missões: `MissionsController`, `MissionRequestsController`, `Mission`, `MissionSubmission`, `MissionRequest`.
- Conquistas e certificados: `AchievementsController`, `CertificatesController`, `Achievement`, `UserAchievement`, `Certificate`, `UserCertificate`.
- Rankings: `RankingsController`, `Public::RankingsController`, `Ranking`, `RankingCalculator`.
- Loja: `StoreController`, `StoreOrdersController`, `StoreItem`, `StoreOrder`, `CurrencyTransaction`.

## Gestão Operacional

`/manage` usa `Manage::ResourceRegistry` como catálogo dos recursos gerenciáveis. Cada entrada define modelo, permissão, campos e ações de membro.

`Manage::BaseController` exige acesso à guilda e permissão operacional. `Manage::ResourcesController` aplica escopo por guilda, monta formulários e executa ações como aprovação, rejeição, fulfillment e sincronização.

O ActiveAdmin em `/admin` continua disponível como fallback técnico para usuários com cargo máximo.

## Integração Discord

Serviços:

- `DiscordApiClient`: cliente REST para Discord, com refresh de token e tratamento de erros.
- `DiscordGuildService`: cria ou atualiza guildas a partir do Discord.
- `DiscordGuildRolesSync`: sincroniza cargos da guilda.
- `DiscordMemberRoleSync`: sincroniza roles e acesso de usuários.
- `DiscordManagedRoleReconciler`: aplica no Discord roles marcadas como `managed_by_app`.

Jobs:

- `DiscordGuildRolesSyncJob`
- `DiscordMembersSyncJob`
- `DiscordManagedRoleReconciliationJob`

As agendas de produção estão em `config/recurring.yml`.

## Serviços de Regras

- `AutomaticMissionEvaluator`: avalia missões automáticas.
- `AchievementEvaluator`: concede conquistas por critérios.
- `RankingCalculator`: calcula rankings sob demanda.
- `PresentationGuildSeeder`: gera dados de apresentação pela task `demo:seed_presentation_guild`.

## Tasks

Tasks Discord ficam em `lib/tasks/discord.rake`:

- `discord:list_guilds`
- `discord:create_guild`
- `discord:sync_guild`
- `discord:sync_all_guilds`
- `discord:set_required_role`
- `discord:remove_required_role`
- `discord:update_guild_access`

Dados demonstrativos ficam em `lib/tasks/demo.rake`.
