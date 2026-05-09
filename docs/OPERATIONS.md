# Operação dos Módulos

## Execução de Comandos

Execute sempre dentro do DevContainer `guild_manager_devcontainer-app-1`:

```bash
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && bin/rails test'
```

Troque o comando final por `bin/rails db:migrate`, `bin/rubocop`, `bin/rails console` ou outro binstub Rails.

## Acesso e Permissões

O login usa Discord OAuth. Após autenticação, o app sincroniza roles do Discord e valida o cargo base da guilda. Ações protegidas usam `PermissionGroup`, com permissões como `manage_events`, `manage_missions`, `manage_rankings`, `manage_store`, `fulfill_store_orders` e `view_audit_logs`.

O ActiveAdmin em `/admin` é fallback técnico e exige cargo máximo (`Role.category = "maximum"`). A operação diária deve ocorrer em `/manage`, que fica disponível para cargo máximo e para cargos com permissões delegadas. O campo legado `is_admin` não concede acesso administrativo sozinho.

Em desenvolvimento, rotas de sessão dev existem apenas com `Rails.env.development?`. Scripts de bootstrap administrativo, como `script/create_first_admin.rb`, também são bloqueados fora de desenvolvimento.

## Módulos Membro

- `/dashboard`: visão geral e atalhos reais para módulos ativos.
- `/events`: RSVP, justificativas e revisão de presença por administradores de evento.
- `/missions`: submissões manuais, recompensas e pedidos de missão.
- `/achievements` e `/certificates`: catálogo, perfil e concessões administrativas.
- `/rankings`: rankings configuráveis por guilda para usuários e squads.
- `/squads`: criação, liderança, convites e revisão de alterações.
- `/store` e `/store/orders`: catálogo, pedidos, cancelamento e saldo de moedas.
- `/manage`: gestão in-app de módulos administrativos conforme cargo/permissão.

## Loja

`StoreItem` controla preço, categoria, status e estoque opcional. `StoreOrder.checkout!` debita moedas imediatamente, reserva estoque e cria auditoria. Cancelamento ou rejeição reembolsa por `CurrencyTransaction` e restaura estoque quando aplicável. Fulfillment é manual via `/manage/store_orders`.

Permissões:

- `manage_store`: cria e edita itens da loja.
- `fulfill_store_orders`: entrega, rejeita ou cancela pedidos.

## Rankings

`Ranking` define escopo (`users` ou `squads`), métrica, ordenação e limite. A tela autenticada usa `/rankings`; a tela pública por guilda usa `/public/guilds/:guild_id/rankings` e mostra apenas rankings ativos. Comece com cálculo direto; snapshots/cache só devem ser adicionados se houver gargalo real.

## Saúde e Configuração

- `/up`: health check padrão simples.
- `/up/full`: health check JSON com banco, Solid Queue e presença de token Discord.
- Active Record Encryption protege tokens Discord salvos em `users`.
- Em produção, configure chaves de criptografia via credentials ou variáveis `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` e `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`.
- `DISCORD_WEBHOOK_SECRET` protege o webhook interno de atualização de membros.

## Jobs Discord

Os jobs recorrentes ficam em `config/recurring.yml` para produção com Solid Queue:

- `DiscordGuildRolesSyncJob`: importa/atualiza roles da guilda a cada 15 minutos.
- `DiscordMembersSyncJob`: sincroniza roles e acesso dos usuários a cada 10 minutos.
- `DiscordManagedRoleReconciliationJob`: aplica/remove no Discord roles marcadas como `managed_by_app` a cada 30 minutos, com enfileiramento imediato em mudanças de certificado.

O webhook interno `POST /webhooks/discord/member_update` aceita `guild_id` e `user_id`, registra auditoria e enfileira sincronização/reconciliação do membro afetado.

Para rodar manualmente no container:

```bash
bin/rails runner 'DiscordGuildRolesSyncJob.perform_now'
bin/rails runner 'DiscordMembersSyncJob.perform_now'
bin/rails runner 'DiscordManagedRoleReconciliationJob.perform_now'
```

Em deploy single-server, habilite o supervisor da fila com `SOLID_QUEUE_IN_PUMA=true`.

## Auditoria

`AuditLog` registra ações de missões, squads, loja e operações administrativas relevantes. O ActiveAdmin expõe `/admin/audit_logs` como leitura. Use `AuditLog.record!` para novas ações administrativas e inclua `origin`, `result` e IDs relevantes em `metadata`.

## Smoke Tests

Além de `bin/rails test`, rode `bin/rails test:system` para validar navegação membro, compra na loja e leitura de auditoria no ActiveAdmin. O driver usa Chromium headless com flags compatíveis com o DevContainer.

## Dados de Apresentação

Para recriar uma guilda mock completa com 100 usuários e 30 dias de uso, execute no container:

```bash
bin/rails demo:seed_presentation_guild
```

Use `USERS=50` para reduzir o volume. A task recria apenas a guilda `Aurora do Abismo`.
