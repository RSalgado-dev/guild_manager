# Operação dos Módulos

## Execução de Comandos

Execute sempre dentro do DevContainer `guild_manager_devcontainer-app-1`:

```bash
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && bin/rails test'
```

Troque o comando final por `bin/rails db:migrate`, `bin/rubocop`, `bin/rails console` ou outro binstub Rails.

## Acesso e Permissões

O login usa Discord OAuth. Após autenticação, o app sincroniza roles do Discord e valida o cargo base da guilda. Ações protegidas usam `PermissionGroup`, com permissões como `manage_events`, `manage_missions`, `manage_rankings`, `manage_store`, `fulfill_store_orders` e `view_audit_logs`.

Usuários com `admin?` ou grupos administrativos acessam o ActiveAdmin em `/admin`. O escopo administrativo é limitado por guilda para usuários não superadmin.

## Módulos Membro

- `/dashboard`: visão geral e atalhos reais para módulos ativos.
- `/events`: RSVP, justificativas e revisão de presença por administradores de evento.
- `/missions`: submissões manuais, recompensas e pedidos de missão.
- `/achievements` e `/certificates`: catálogo, perfil e concessões administrativas.
- `/rankings`: rankings configuráveis por guilda para usuários e squads.
- `/squads`: criação, liderança, convites e revisão de alterações.
- `/store` e `/store/orders`: catálogo, pedidos, cancelamento e saldo de moedas.

## Loja

`StoreItem` controla preço, categoria, status e estoque opcional. `StoreOrder.checkout!` debita moedas imediatamente, reserva estoque e cria auditoria. Cancelamento ou rejeição reembolsa por `CurrencyTransaction` e restaura estoque quando aplicável. Fulfillment é manual via ActiveAdmin.

Permissões:

- `manage_store`: cria e edita itens da loja.
- `fulfill_store_orders`: entrega, rejeita ou cancela pedidos.

## Rankings

`Ranking` define escopo (`users` ou `squads`), métrica, ordenação e limite. A tela pública mostra apenas rankings ativos da guilda atual. Comece com cálculo direto; snapshots/cache só devem ser adicionados se houver gargalo real.

## Jobs Discord

Os jobs recorrentes ficam em `config/recurring.yml` para produção com Solid Queue:

- `DiscordGuildRolesSyncJob`: importa/atualiza roles da guilda a cada 15 minutos.
- `DiscordMembersSyncJob`: sincroniza roles e acesso dos usuários a cada 10 minutos.
- `DiscordManagedRoleReconciliationJob`: aplica/remove no Discord roles marcadas como `managed_by_app` a cada 5 minutos.

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
