# Status Atual do Desenvolvimento

Última atualização: 2026-03-12

## Visão Geral
A base do sistema está funcional para autenticação Discord, segregação por guilda, cadastro de personagens e controle de acesso por grupos de permissão.

## Módulos Implementados

### 1. Autenticação e vínculo com Discord
- Login via OAuth Discord.
- Descoberta de guildas do usuário no Discord.
- Criação/atualização de usuário local associando à guilda autorizada.
- Sincronização de roles Discord para roles locais.

Arquivos principais:
- `app/controllers/sessions_controller.rb`
- `app/models/user.rb`
- `app/services/discord_guild_service.rb`

### 2. Controle de acesso por guilda
- Cada guilda pode definir cargo obrigatório (`required_discord_role_id`).
- Usuários sem cargo exigido são direcionados para área restrita.
- Campo `has_guild_access` atualizado após sincronização.

Arquivos principais:
- `app/models/guild.rb`
- `app/models/user.rb`
- `app/controllers/application_controller.rb`
- `app/controllers/access/dashboard_controller.rb`

### 3. Personagens de jogo
- Usuário pode ter múltiplos personagens.
- Cada guilda define um template de personagem (JSON) com campos obrigatórios/opcionais.
- Validação de campos dinâmicos baseada no template da guilda.
- Um único personagem principal por usuário (`is_primary = true`).
- Promoção automática de principal em criação/remoção conforme regras de consistência.

Arquivos principais:
- `app/models/game_character.rb`
- `app/models/guild.rb`
- `app/controllers/access/characters_controller.rb`
- `app/views/access/characters/*.erb`

### 4. Permissionamento por grupos
- Criação de `PermissionGroup` por guilda.
- Associação de um grupo a uma ou mais roles Discord locais.
- Permissões granulares implementadas:
  - `manage_members`
  - `manage_store`
  - `manage_events`
  - `manage_certificates`
- Grupo padrão `Administração` criado automaticamente com acesso total (`all_access`).
- Método central de checagem: `user.has_permission?(permission_key)`.

Arquivos principais:
- `app/models/permission_group.rb`
- `app/models/permission_group_role.rb`
- `app/models/user.rb`
- `app/admin/permission_groups.rb`

## Estratégia de Sincronização de Roles Discord
Para reduzir janela de inconsistência entre Discord e sistema interno:

1. Login:
- Sincronização imediata dos roles.

2. Acesso à área interna:
- Revalidação automática com TTL (`DISCORD_ROLE_SYNC_MAX_AGE = 2.minutes`).

3. Ações protegidas por permissão:
- Revalidação com TTL curto (`PERMISSION_CHECK_SYNC_MAX_AGE = 30.seconds`) antes de `require_permission`.

4. Controle de sincronização:
- `users.discord_roles_synced_at` para evitar chamadas excessivas.

Arquivos principais:
- `app/models/user.rb`
- `app/controllers/access_controller.rb`
- `app/controllers/application_controller.rb`
- `db/migrate/20260312131500_add_discord_roles_synced_at_to_users.rb`

## ActiveAdmin
Painéis administrativos ativos para:
- Guilds
- Users
- Roles
- Permission Groups
- Squads

Com formulários e listagens funcionais para gerenciamento operacional.

## Estado de Qualidade
- Suite de testes verde.
- RuboCop sem offenses.
- Migrações recentes aplicadas para:
  - Template e dados dinâmicos de personagem
  - Personagem principal
  - Grupos de permissão
  - Timestamp de sincronização de roles

## Decisões Técnicas Relevantes
- Migração de permission groups isolada de modelos da aplicação (evita acoplamento temporal de migrations).
- Checagem de permissão otimizada com `exists?` em SQL (evita carga desnecessária de objetos em memória).

## Pontos em Aberto (Próximos Passos)
1. Aplicar `require_permission` nos módulos funcionais reais (membros, loja, eventos, certificados) ao implementar/expandir controllers.
2. Criar job recorrente para sincronização proativa de roles em usuários ativos.
3. Adicionar auditoria explícita para mudanças de grupos/permissões administrativas.
4. Criar testes de integração focados em revogação de permissão em tempo real (Discord -> sistema).
5. Evoluir catálogo de permissões com versionamento e migração de compatibilidade.
