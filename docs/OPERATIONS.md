# Operação

## Comandos

Execute sempre dentro do DevContainer:

```bash
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && bin/rails test'
```

Troque o comando final por `bin/rails db:migrate`, `bin/rubocop`, `bin/rails console`, `bin/dev` ou outro binstub.

## Acesso Administrativo

O login usa Discord OAuth. Depois do login, o app sincroniza roles e calcula o acesso interno.

Camadas de autorização:

- `Guild#required_discord_role_id`: cargo base opcional para liberar a área interna.
- `Role`: cargo local sincronizado do Discord ou gerenciado pelo app.
- `PermissionGroup`: permissões operacionais delegadas a roles.
- Cargo `maximum`: acesso total à guilda, `/manage` e `/admin`.

`/manage` é o painel operacional principal. `/admin` é fallback técnico e exige cargo máximo. A flag legada `users.is_admin` não deve ser usada como única fonte de autorização.

## Módulos

- `/dashboard`: resumo da guilda para membros.
- `/profile`: perfil, XP, moedas, roles, conquistas, certificados e personagens.
- `/events`: RSVP, justificativas e revisão de presença.
- `/missions`: submissões, revisão e recompensas.
- `/achievements` e `/certificates`: catálogo e detalhes.
- `/rankings`: rankings autenticados.
- `/public/guilds/:guild_id/rankings`: rankings públicos por guilda.
- `/squads`: squads, liderança, convites e revisões.
- `/store` e `/store/orders`: catálogo, pedidos, cancelamento e saldo.
- `/manage`: CRUD e ações administrativas com permissão.

## Permissões

As permissões válidas ficam em `PermissionGroup::AVAILABLE_PERMISSIONS`:

```text
manage_guild_settings
manage_roles
manage_administrative_roles
manage_members
manage_events
manage_missions
review_mission_submissions
manage_achievements
grant_achievements
manage_certificates
grant_certificates
manage_rankings
manage_store
fulfill_store_orders
view_audit_logs
```

## Loja

`StoreOrder.checkout!` debita moedas imediatamente, reserva estoque quando aplicável e registra auditoria. Cancelamento ou rejeição reembolsa por `CurrencyTransaction` e restaura estoque. Fulfillment é manual em `/manage/store_orders`.

## Rankings

`Ranking` define escopo (`users` ou `squads`), métrica, direção de ordenação, limite e posição. O cálculo é direto via `RankingCalculator`; só adicione cache/snapshot se houver gargalo medido.

## Saúde

- `/up`: health check simples do Rails.
- `/up/full`: JSON com banco, Solid Queue e presença de token Discord.

Em produção, configure:

- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
- `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
- `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`
- `DISCORD_WEBHOOK_SECRET`
- `SOLID_QUEUE_IN_PUMA=true` em deploy single-server, se a fila rodar no Puma.

## Jobs Discord

Agendas de produção ficam em `config/recurring.yml`:

- `DiscordGuildRolesSyncJob`: sincroniza roles da guilda.
- `DiscordMembersSyncJob`: sincroniza roles e acesso dos usuários.
- `DiscordManagedRoleReconciliationJob`: aplica/remove roles gerenciadas pelo app no Discord.

Execução manual:

```bash
bin/rails runner 'DiscordGuildRolesSyncJob.perform_now'
bin/rails runner 'DiscordMembersSyncJob.perform_now'
bin/rails runner 'DiscordManagedRoleReconciliationJob.perform_now'
```

O webhook `POST /webhooks/discord/member_update` aceita `guild_id` e `user_id`, exige `DISCORD_WEBHOOK_SECRET` em produção, registra auditoria e enfileira sincronização do membro.

## Auditoria

Use `AuditLog.record!` em novas ações administrativas ou financeiras. Inclua `origin`, `result` e IDs relevantes em `metadata`. Não grave tokens, segredos, senhas, authorization headers ou emails crus.

## Dados de Apresentação

```bash
bin/rails demo:seed_presentation_guild
```

Use `USERS=50` para reduzir o volume. A task recria apenas a guilda de apresentação.
