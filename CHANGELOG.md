# Changelog - Sistema de Guildas

## Data: 13 de Janeiro de 2026

### 📝 Resumo das Alterações

Este documento descreve as alterações implementadas no sistema de guildas, incluindo todos os modelos, relacionamentos e funcionalidades adicionadas.

---

## 🏰 Modelos Criados

### 1. Guild (Guilda)
**Arquivo**: `app/models/guild.rb`  
**Migração**: `db/migrate/20260113144810_create_guilds.rb`

#### Atributos:
- `name` (string, obrigatório, máx 100 caracteres)
- `description` (text)

#### Relacionamentos:
- `has_many :users` - Membros da guilda (dependent: nullify)
- `has_many :roles` - Cargos da guilda (dependent: destroy)
- `has_many :squads` - Esquadrões da guilda (dependent: destroy)
- `has_many :missions` - Missões (dependent: destroy)
- `has_many :events` - Eventos (dependent: destroy)
- `has_many :achievements` - Conquistas (dependent: destroy)
- `has_many :certificates` - Certificados (dependent: destroy)

#### Validações:
- Nome deve estar presente
- Nome deve ter no máximo 100 caracteres

---

### 2. Role (Cargo)
**Arquivo**: `app/models/role.rb`  
**Migração**: `db/migrate/20260113145829_create_roles.rb`

#### Atributos:
- `guild_id` (referência, obrigatório)
- `name` (string, obrigatório, máx 50 caracteres)
- `description` (text)
- `is_admin` (boolean, padrão: false)
- `discord_role_id` (string)

#### Relacionamentos:
- `belongs_to :guild`
- `has_many :user_roles` (dependent: destroy)
- `has_many :users, through: :user_roles`
- `has_many :role_certificate_requirements` (dependent: destroy)
- `has_many :required_certificates, through: :role_certificate_requirements`

#### Métodos:
- `admin?` - Retorna se o cargo é administrativo

#### Validações:
- Nome deve estar presente
- Nome deve ter no máximo 50 caracteres

---

### 3. User (Usuário)
**Arquivo**: `app/models/user.rb`  
**Migração**: `db/migrate/20260113149538_create_users.rb`

#### Atributos:
- `guild_id` (referência, obrigatório)
- `squad_id` (referência, opcional)
- `discord_id` (string, obrigatório, único)
- `discord_username` (string)
- `discord_nickname` (string)
- `discord_avatar_url` (string)
- `discord_access_token` (string)
- `discord_refresh_token` (string)
- `discord_token_expires_at` (datetime)
- `xp_points` (integer, padrão: 0)
- `currency_balance` (integer, padrão: 0)
- `email` (string)

#### Relacionamentos:
- `belongs_to :guild`
- `belongs_to :squad` (opcional)
- `has_many :user_roles` (dependent: destroy)
- `has_many :roles, through: :user_roles`
- `has_one :squad_led` (Squad onde é líder, dependent: nullify)
- `has_many :event_participations` (dependent: destroy)
- `has_many :events, through: :event_participations`
- `has_many :mission_submissions` (dependent: destroy)
- `has_many :missions, through: :mission_submissions`
- `has_many :currency_transactions` (dependent: destroy)
- `has_many :user_achievements` (dependent: destroy)
- `has_many :achievements, through: :user_achievements`
- `has_many :user_certificates` (dependent: destroy)
- `has_many :certificates, through: :user_certificates`
- `has_many :audit_logs` (dependent: nullify)
- `has_many :uploaded_squad_emblems` (Squads com emblema enviado, dependent: nullify)
- `has_many :reviewed_squad_emblems` (Squads com emblema revisado, dependent: nullify)

#### Métodos:
- `admin?` - Verifica se o usuário tem algum cargo administrativo
- `primary_role` - Retorna o cargo primário do usuário

#### Validações:
- `discord_id` deve estar presente e ser único
- `xp_points` deve ser maior ou igual a 0
- `currency_balance` deve ser maior ou igual a 0

---

### 4. UserRole (Cargo do Usuário)
**Arquivo**: `app/models/user_role.rb`  
**Migração**: `db/migrate/20260113152640_create_user_roles.rb`

#### Atributos:
- `user_id` (referência, obrigatório)
- `role_id` (referência, obrigatório)
- `primary` (boolean, padrão: false)

#### Relacionamentos:
- `belongs_to :user`
- `belongs_to :role`

#### Scopes:
- `primary` - Filtra cargos marcados como primários

#### Validações:
- Combinação de `user_id` e `role_id` deve ser única (um usuário não pode ter o mesmo cargo duas vezes)

---

### 5. Squad (Esquadrão)
**Arquivo**: `app/models/squad.rb`  
**Migração**: `db/migrate/20260113154808_create_squads.rb`

#### Atributos:
- `guild_id` (referência, obrigatório)
- `name` (string, obrigatório)
- `description` (text)
- `leader_id` (referência User, obrigatório)
- `emblem_status` (enum: none, pending, approved, rejected)
- `emblem_uploaded_by_id` (referência User, opcional)
- `emblem_reviewed_by_id` (referência User, opcional)
- `emblem_reviewed_at` (datetime)
- `emblem_rejection_reason` (text)

#### Relacionamentos:
- `belongs_to :guild`
- `belongs_to :leader` (User)
- `has_many :users` (dependent: nullify)
- `belongs_to :emblem_uploaded_by` (User, opcional)
- `belongs_to :emblem_reviewed_by` (User, opcional)
- `has_one_attached :emblem` (Active Storage)
- `has_one_attached :emblem_pending` (Active Storage)

#### Enums:
- `emblem_status`: none, pending, approved, rejected

#### Validações:
- Nome deve estar presente

---

### 6. AuditLog (Log de Auditoria)
**Arquivo**: `app/models/audit_log.rb`  
**Migração**: `db/migrate/20260113157933_create_audit_logs.rb`

#### Atributos:
- `user_id` (referência, opcional)
- `guild_id` (referência, opcional)
- `action` (string) - Ação realizada
- `entity_type` (string) - Tipo da entidade afetada
- `entity_id` (bigint) - ID da entidade afetada

#### Relacionamentos:
- `belongs_to :user` (opcional)
- `belongs_to :guild` (opcional)

#### Métodos:
- `entity` - Retorna a entidade relacionada (polimórfica) usando `entity_type` e `entity_id`

#### Scopes:
- `recent` - Ordena por criação mais recente
- `for_guild(guild_id)` - Filtra por guilda
- `by_action(action)` - Filtra por ação

#### Funcionalidade:
Sistema de auditoria para rastrear ações importantes no sistema, incluindo:
- Quem executou a ação (user_id)
- Em qual guilda (guild_id)
- Qual ação foi executada (action)
- Qual entidade foi afetada (entity_type + entity_id)

---

## 🔄 Migrações Adicionais

### 7. Adição de squad_id ao User
**Migração**: `db/migrate/20260113157933_add_squad_to_user.rb`

Adiciona a coluna `squad_id` à tabela `users` para permitir que usuários pertençam a um esquadrão.

---

## 🎯 Funcionalidades Implementadas

### Sistema de Permissões
- Cargos com flag `is_admin`
- Verificação de permissões através do método `admin?` em User e Role

### Sistema de Esquadrões
- Líderes de esquadrão
- Sistema de emblemas com aprovação
- Estados de emblema (pendente, aprovado, rejeitado)

### Sistema de Auditoria
- Rastreamento de ações
- Associação com usuários e guildas
- Busca e filtragem de logs

### Gamificação
- Pontos de XP
- Moeda virtual
- Sistema de conquistas
- Certificados

### Integração Discord
- Armazenamento de dados do Discord
- Tokens de acesso OAuth
- Sincronização de cargos

---

## 📊 Diagrama de Relacionamentos

```
Guild (Guilda)
├── has_many Users (Membros)
├── has_many Roles (Cargos)
├── has_many Squads (Esquadrões)
└── has_many AuditLogs

Role (Cargo)
├── belongs_to Guild
├── has_many UserRoles
└── has_many Users (through UserRoles)

User (Usuário)
├── belongs_to Guild
├── belongs_to Squad (opcional)
├── has_many UserRoles
├── has_many Roles (through UserRoles)
├── has_one Squad (como líder)
└── has_many AuditLogs

Squad (Esquadrão)
├── belongs_to Guild
├── belongs_to Leader (User)
└── has_many Users (membros)

UserRole (Cargo do Usuário)
├── belongs_to User
└── belongs_to Role

AuditLog (Log de Auditoria)
├── belongs_to User (opcional)
└── belongs_to Guild (opcional)
```

---

## 🧪 Testes

Testes unitários foram implementados para todos os modelos em:
- `test/models/guild_test.rb`
- `test/models/role_test.rb`
- `test/models/user_test.rb`
- `test/models/squad_test.rb`
- `test/models/user_role_test.rb`
- `test/models/audit_log_test.rb`

Cada teste cobre:
- ✅ Validações de presença e formato
- ✅ Relacionamentos entre modelos
- ✅ Métodos customizados
- ✅ Scopes e queries
- ✅ Comportamento de dependent destroy/nullify

---

## 📝 Próximos Passos

- [ ] Implementar controllers e rotas
- [ ] Adicionar views para gerenciamento
- [ ] Implementar autenticação OAuth com Discord
- [ ] Criar sistema de permissões granular
- [ ] Adicionar validações de negócio mais complexas
- [ ] Implementar webhooks do Discord
- [ ] Adicionar testes de integração

---

## 🔒 Segurança

- Tokens de acesso são armazenados criptografados
- Logs de auditoria rastreiam todas as ações importantes
- Sistema de permissões baseado em cargos
- Validações de unicidade para prevenir duplicatas
