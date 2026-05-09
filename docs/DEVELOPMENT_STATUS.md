# Status Atual do Desenvolvimento

Última atualização: 2026-05-05

## Visão Geral

A aplicação está funcional como plataforma multi-guild com login Discord, sincronização de roles, controle de permissões por grupo, módulos de membros e operação administrativa dentro da própria aplicação em `/manage`. O ActiveAdmin permanece como fallback técnico restrito ao cargo máximo. A execução local deve ocorrer dentro do DevContainer `guild_manager_devcontainer-app-1`.

## Módulos Implementados

### Autenticação, Guildas e Permissões

- Login via Discord OAuth.
- Descoberta de guilda do usuário e vínculo local.
- Sincronização de roles Discord com TTL de acesso interno, TTL curto para permissões, refresh de access token e fallback fechado fora de desenvolvimento.
- Cargo base opcional por guilda (`required_discord_role_id`).
- Roles categorizadas como base, cosmética, especial, administrativa ou máxima.
- `PermissionGroup` com permissões granulares: membros, roles, eventos, missões, conquistas, certificados, rankings, loja e auditoria.
- `/admin` exige cargo máximo; permissões delegadas operam em `/manage`.
- Tokens Discord são criptografados com Active Record Encryption.

### Perfil, Personagens e Squads

- Perfil com XP, moedas, conquistas, certificados, roles e estatísticas de presença.
- Múltiplos personagens por usuário, template dinâmico por guilda e personagem principal único.
- Squads com líder, convites, revisão de alterações de perfil e emblema.

### Eventos e Missões

- Eventos com RSVP, justificativa, revisão de presença, recompensas de XP/moeda e auditoria.
- Missões ativas por guilda, submissões manuais, limite por período, aprovação/rejeição e distribuição de recompensa.
- Pedidos de missão por membros elegíveis.
- Missões automáticas cobrem atualização semanal de personagem, primeiro login da semana, presença em eventos e sequência de missões recompensadas.

### Conquistas, Certificados e Rankings

- Conquistas predefinidas ou individuais, catálogo, perfil e recompensa cosmética de cor de nome.
- Avaliação automática de conquistas por critérios de XP, nível, saldo, eventos participados e missões recompensadas.
- Certificados com concessão, revogação, expiração e vínculo obrigatório com roles cosméticas.
- Rankings configuráveis por guilda para usuários e squads, com rota autenticada e visualização pública por guilda.

### Loja

- Catálogo em `/store` e pedidos em `/store/orders`.
- `StoreItem` com categoria, preço, estoque opcional, status e fulfillment manual.
- `StoreOrder` com débito imediato, reserva de estoque, cancelamento/rejeição com reembolso e auditoria.
- ActiveAdmin para itens e pedidos com permissões `manage_store` e `fulfill_store_orders`.

### Gestão In-App, ActiveAdmin e Auditoria

- `/manage` reúne CRUD e ações administrativas para guilda, membros, cargos, permissões, squads, eventos, missões, conquistas, certificados, rankings, loja e auditoria.
- Cargo máximo acessa todos os módulos; cargos delegados acessam apenas módulos permitidos por `PermissionGroup`.
- Recursos administrativos para guilds, users, roles, permission groups, squads, events, missions, achievements, certificates, rankings, store items, store orders e audit logs.
- ActiveAdmin em `/admin` é fallback técnico max-only com escopo por guilda.
- `AuditLog` exposto como leitura em `/admin/audit_logs`.
- Ações administrativas relevantes usam `AuditLog.record!`.
- Metadados de auditoria filtram tokens, segredos, senhas, authorization headers e emails antes da gravação.

### Jobs Discord e Smoke Tests

- `DiscordGuildRolesSyncJob`, `DiscordMembersSyncJob` e `DiscordManagedRoleReconciliationJob` estão configurados em `config/recurring.yml`.
- Reconciliação assíncrona de roles gerenciadas pelo app é disparada por certificados com role `managed_by_app`.
- Webhook interno de atualização de membro Discord enfileira sync e reconciliação sob segredo compartilhado.
- `/up/full` expõe health check operacional para banco, Solid Queue e configuração Discord.
- System smoke tests cobrem navegação de membro, compra na loja, rankings e leitura de auditoria no ActiveAdmin.

## Qualidade

- Suite completa executada dentro do container.
- RuboCop sem offenses.
- Testes cobrem modelos, controllers, jobs, serviços, permissões, área `/manage`, Discord WebMock, rankings, loja, squads, missões, eventos e smoke/system.

## Próximos Pontos Técnicos

1. Criar jobs de expiração/reconciliação de certificados expirados.
2. Adicionar observabilidade operacional para falhas de jobs Discord.
3. Avaliar cache/snapshots para rankings apenas se surgirem gargalos reais.
4. Evoluir métricas administrativas se o uso real justificar dashboards dedicados.
