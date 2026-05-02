# Plano de Implementação e Refatoração - Guild Manager

## Resumo

A codebase atual já entrega autenticação Discord, acesso por cargo base, personagens, squads com revisão, eventos básicos, XP/moedas, Permission Groups e ActiveAdmin parcial. Para alcançar a aplicação descrita em `idea.md`, o projeto será evoluído em etapas com fundação primeiro, ActiveAdmin como painel operacional, app como fonte autoritativa para cargos gerenciados e loja v1 com pedido/entrega manual.

Todos os comandos de desenvolvimento, teste e CI devem rodar dentro do DevContainer. No ambiente analisado, não havia container ativo e `bin/rails test` falhou no host por ausência/permissão de Ruby; a validação real começa após subir o container.

## Backlog por Etapas

## Progresso Atual

- Etapa 0 concluída no container existente `guild_manager_devcontainer-app-1`: `bin/rails test` e `bin/rubocop` passaram dentro do container.
- `bin/ci` executa até o fim, mas falha em `bin/bundler-audit` por advisories em dependências; testes, RuboCop, Brakeman, importmap audit, system tests e seeds passam.
- Etapa 1 concluída: `Role` agora possui categoria operacional e flag de gerenciamento pelo app; `PermissionGroup` possui catálogo expandido de permissões para os módulos planejados.
- ActiveAdmin passou a usar autorização por permissão e escopo por guilda; o painel admin é acessível por usuários com grupos operacionais, não apenas por superadmin.
- Etapa 2 concluída: chamadas Discord foram extraídas para serviços, roles gerenciadas pelo app são reconciliadas por jobs, roles externas são apenas importadas e mudanças de cargo registram auditoria.
- Validação da Etapa 2: `bin/rails test` passou com 356 testes e `bin/rubocop` não encontrou offenses, ambos dentro do container.
- Etapa 3 concluída: eventos agora seguem a matriz de recompensa do `idea.md`, fechamento duplicado não distribui recompensa novamente e criação, RSVP, fechamento e recompensas geram auditoria.
- Validação da Etapa 3: `bin/rails test` passou com 358 testes e `bin/rubocop` não encontrou offenses, ambos dentro do container.

### Etapa 0 - Ambiente, Qualidade e Base Operacional

- Corrigir DevContainer antes de qualquer feature: validar Ruby/rbenv no `PATH`, `bin/setup`, `bin/dev`, banco Postgres, Tailwind e `bin/ci`.
- Ajustar configuração recorrente/queue se necessário e garantir que `bin/rails test`, `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit` e `bin/ci` rodam dentro do container.
- Atualizar docs de setup para explicitar fluxo único: abrir/subir DevContainer, nunca executar Rails no host.

### Etapa 1 - Fundação de Cargos, Permissões e Admin (concluída)

- Manter `guilds.required_discord_role_id/name` como o cargo base de acesso.
- Evoluir `Role` com categoria: `base`, `cosmetic`, `special`, `administrative`; adicionar `managed_by_app:boolean`.
- Tratar cargo máximo como role administrativa vinculada a `PermissionGroup` com `all_access=true`; `users.is_admin` fica apenas como superadmin/dev fallback.
- Expandir permissões para cobrir: configurações da guilda, roles, roles administrativas, membros/squads, eventos, missões, conquistas, certificados, rankings, loja, fulfillment e auditoria.
- Refatorar ActiveAdmin para autorização granular por permissão e escopo de guilda: officers não editam cargos administrativos; apenas `all_access` configura guilda e grupos administrativos.

### Etapa 2 - Sincronização Discord Autoritativa pelo App (concluída)

- Extrair chamadas Discord de `User` para serviços dedicados: cliente REST, sync de guild/roles/membro e reconciliador de cargos.
- Para roles `managed_by_app`, o app mantém o estado desejado e reconcilia no Discord; para roles não gerenciadas, o app apenas importa o estado do Discord.
- Criar jobs recorrentes: sync de roles da guilda, sync de membros ativos e reconciliação de assignments pendentes.
- Preservar sync atual no login e nas permissões com TTL curto, mas mover lógica para serviços/jobs.
- Registrar auditoria para mudanças de cargo, origem (`app`, `discord`, `job`, `admin`) e resultado.

### Etapa 3 - Eventos (concluída)

- Corrigir matriz de recompensa para bater com o `idea.md`: confirmou+participou 100%, confirmou+faltou 0%, justificou+justificado 20%, justificou+participou 50%, sem resposta+faltou 0%, sem resposta+participou 25%.
- Tornar fechamento idempotente: impedir recompensa duplicada se evento já foi concluído.
- Melhorar revisão com grupos pré-preenchidos por resposta e edição final por admin.
- Adicionar auditoria de criação, RSVP, fechamento e recompensas.
- Manter rotas atuais de eventos, com `manage_events` para criação/revisão.

### Etapa 4 - Missões v1

- Expandir `Mission` com tipo `manual`/`automatic`, frequência, limite de submissões, modo de recompensa `fixed`/`per_unit`, XP/moeda por unidade e metadados seguros.
- Expandir `MissionSubmission` com status `pending`, `approved`, `rejected`, `rewarded`, comprovante via ActiveStorage, quantidade, revisão, notas e recompensa calculada.
- Implementar fluxo membro: listar missões, enviar comprovante, acompanhar status.
- Implementar fluxo admin: criar missões, revisar submissões, aprovar/rejeitar e distribuir recompensa.
- Implementar primeira missão automática: atualizar personagem principal dentro do período semanal.
- Adicionar `MissionRequest` para cargos especiais, como Artesão, solicitarem missões à administração.

### Etapa 5 - Conquistas e Certificados

- Evoluir `Achievement` com tipo `predefined`/`individual`, visibilidade `catalog`/`profile_only`, critérios, XP/moeda e recompensa de personalização.
- v1 de personalização: desbloqueio de cor do nome no perfil via achievement preexistente; conquistas individuais não dão personalização.
- Criar catálogo público de conquistas preexistentes e destaque de conquistas individuais no perfil.
- Evoluir `Certificate` para vínculo opcional obrigatório com uma `Role` cosmética; conceder certificado pode reconciliar cargo Discord se a role for gerenciada pelo app.
- Criar telas/admin resources para conceder, revogar e expirar certificados.

### Etapa 6 - Rankings

- Criar `Ranking` configurável por guilda com escopo `users`/`squads`, métrica, ordenação, limite e status ativo.
- Métricas v1: nível, XP, moedas ganhas, poder do personagem principal, XP total do squad, média de nível do squad e número de membros.
- Criar rota pública `/rankings` com abas por ranking ativo.
- Adicionar cache/snapshot apenas se cálculo direto ficar pesado; começar com queries otimizadas.

### Etapa 7 - Loja v1

- Criar `StoreItem` com guilda, nome, descrição, categoria, preço, estoque opcional, status e fulfillment manual.
- Criar `StoreOrder` com usuário, item, preço pago, status `pending`, `fulfilled`, `rejected`, `canceled`, timestamps e notas admin.
- No pedido, debitar moedas imediatamente; ao rejeitar/cancelar, reembolsar por `CurrencyTransaction`.
- Criar tela membro para catálogo/pedidos e ActiveAdmin para gerenciar itens e cumprir pedidos.
- Proteger criação/edição por `manage_store` e fulfillment por `fulfill_store_orders`.

### Etapa 8 - UX, Navegação, Auditoria e Documentação

- Substituir cards "disponível" sem rota por links reais ou status "em breve" até o módulo existir.
- Padronizar dashboard, perfil, squads, eventos, missões, rankings e loja com navegação consistente.
- Cobrir ações administrativas relevantes com `AuditLog`.
- Atualizar README/docs conforme cada etapa: permissões, Discord sync, missões, loja, rankings e operação admin.

## Interfaces e Contratos Principais

- Rotas membro novas: `/missions`, `/achievements`, `/certificates`, `/rankings`, `/store`, `/store/orders`.
- ActiveAdmin evoluído para: guilds, users, roles, permission groups, events, missions, mission requests, achievements, certificates, rankings, store items, store orders e audit logs.
- Serviços novos: Discord client/sync/reconcile, reward distribution, mission evaluation, achievement evaluator, ranking calculator e store checkout/refund.
- Jobs novos: sync recorrente de roles/membros Discord, reconciliação de cargos gerenciados, avaliação periódica de missões automáticas e conquistas.

## Plano de Testes

- Etapa 0: `bin/rails test`, `bin/rubocop`, `bin/ci` dentro do DevContainer.
- Model tests para novas validações, enums, cálculos de recompensa, loja, rankings e permissões.
- Controller/integration tests para fluxos membro/admin de eventos, missões, loja e rankings.
- WebMock para todas as chamadas Discord; nenhum teste deve depender de rede real.
- System smoke tests para login dev, dashboard, perfil, eventos, missões, loja e ActiveAdmin.
- Regressão obrigatória: usuário sem cargo base vai para `/restricted`; cargo removido no Discord revoga acesso após sync.

## Assumptions Fixadas

- ActiveAdmin será o painel administrativo padrão.
- O app é autoritativo apenas para roles marcadas como `managed_by_app`; roles externas continuam espelhadas do Discord.
- Loja v1 usa pedido manual com débito imediato e reembolso em rejeição/cancelamento.
- Missões v1 incluem fluxo manual completo e uma automação inicial de atualização do personagem principal.
- A arquitetura multi-guild atual será preservada.
