# Changelog - Sistema de Guildas

## Data: 13 de Janeiro de 2026

### 📝 Resumo das Alterações

Este documento descreve todas as alterações implementadas no sistema de guildas, incluindo 12 modelos principais, relacionamentos complexos, sistema de gamificação completo, eventos e missões.

**Total de Testes**: 155 testes (todos passando ✅)

---

## 🏰 Modelos Criados

### 1. Guild (Guilda)
**Arquivo**: `app/models/guild.rb`  
**Migração**: `db/migrate/20260113144810_create_guilds.rb`

#### Atributos:
- `name` (string, obrigatório, máx 100 caracteres)
- `description` (text)

#### Relacionamentos:
- `has_many :users` - Membros da guilda (dependent: destroy)
- `has_many :roles` - Cargos da guilda (dependent: destroy)
- `has_many :squads` - Esquadrões da guilda (dependent: destroy)
- `has_many :missions` - Missões (dependent: destroy)
- `has_many :events` - Eventos (dependent: destroy)

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

### 7. Event (Evento)
**Arquivo**: `app/models/event.rb`

#### Atributos:
- `guild_id` (referência, obrigatório)
- `creator_id` (referência User, obrigatório)
- `title` (string, obrigatório)
- `description` (text)
- `event_type` (string, obrigatório)
- `starts_at` (datetime, obrigatório)
- `ends_at` (datetime)
- `status` (enum: scheduled, completed, canceled)
- `reward_currency` (integer)
- `reward_xp` (integer)

#### Relacionamentos:
- `belongs_to :guild`
- `belongs_to :creator` (User)
- `has_many :event_participants` (dependent: destroy)
- `has_many :users, through: :event_participants`

#### Métodos:
- `finished?` - Retorna true se o evento já terminou (ends_at no passado)

#### Enums:
- `status`: scheduled, completed, canceled

#### Validações:
- Título deve estar presente
- Tipo de evento deve estar presente
- Data de início deve estar presente

---

### 8. EventParticipation (Participação em Evento)
**Arquivo**: `app/models/event_participation.rb`

#### Atributos:
- `event_id` (referência, obrigatório)
- `user_id` (referência, obrigatório)
- `rsvp_status` (string) - Status de confirmação: yes, maybe, no
- `attended` (boolean, padrão: false)
- `rewarded_at` (datetime)

#### Relacionamentos:
- `belongs_to :event`
- `belongs_to :user`

#### Scopes:
- `attended` - Filtra participações onde o usuário compareceu

#### Validações:
- Combinação de `event_id` e `user_id` deve ser única
- `rsvp_status` deve ser: yes, maybe, no ou em branco

---

### 9. Mission (Missão)
**Arquivo**: `app/models/mission.rb`

#### Atributos:
- `guild_id` (referência, obrigatório)
- `name` (string, obrigatório)
- `description` (text)
- `frequency` (enum: weekly)
- `reward_currency` (integer, >= 0)
- `reward_xp` (integer, >= 0)
- `active` (boolean)

#### Relacionamentos:
- `belongs_to :guild`
- `has_many :mission_submissions` (dependent: destroy)
- `has_many :users, through: :mission_submissions`

#### Enums:
- `frequency`: weekly (outras frequências comentadas para implementação futura)

#### Validações:
- Nome deve estar presente
- `reward_currency` deve ser maior ou igual a 0
- `reward_xp` deve ser maior ou igual a 0

---

### 10. MissionSubmission (Submissão de Missão)
**Arquivo**: `app/models/mission_submission.rb`  
**Migração**: `db/migrate/20260113165554_create_mission_submissions.rb`

#### Atributos:
- `mission_id` (referência, obrigatório)
- `user_id` (referência, obrigatório)
- `week_reference` (string, obrigatório) - Formato ISO 8601 (ex: "2026-W03")
- `answers_json` (jsonb, padrão: {}) - JSON com respostas da missão
- `rewarded_at` (datetime)

#### Relacionamentos:
- `belongs_to :mission`
- `belongs_to :user`

#### Métodos:
- `week` - Alias para `week_reference`

#### Validações:
- `week_reference` deve estar presente
- Combinação de `mission_id`, `user_id` e `week_reference` deve ser única

---

### 11. Achievement (Conquista)
**Arquivo**: `app/models/achievement.rb`  
**Migração**: `db/migrate/20260113182143_create_achievements.rb`

#### Atributos:
- `guild_id` (referência, obrigatório)
- `code` (string, obrigatório) - Código único da conquista por guilda
- `name` (string, obrigatório) - Nome da conquista
- `description` (text) - Descrição da conquista
- `category` (string) - Categoria (raids, events, leadership, etc)
- `icon_url` (string) - URL do ícone
- `active` (boolean, padrão: true) - Se a conquista está ativa

#### Relacionamentos:
- `belongs_to :guild`
- `has_many :user_achievements` (dependent: destroy)
- `has_many :users, through: :user_achievements`

#### Validações:
- `code` deve estar presente e ser único por guilda
- `name` deve estar presente

#### Índices:
- Índice único em `[guild_id, code]`
- Índice em `[guild_id, name]`

---

### 12. UserAchievement (Conquista do Usuário)
**Arquivo**: `app/models/user_achievement.rb`  
**Migração**: `db/migrate/20260113182402_create_user_achievements.rb`

#### Atributos:
- `user_id` (referência, obrigatório)
- `achievement_id` (referência, obrigatório)
- `earned_at` (datetime, obrigatório) - Quando foi conquistada
- `source_type` (string) - Tipo polimórfico da origem (Event, Mission, etc)
- `source_id` (bigint) - ID polimórfico da origem

#### Relacionamentos:
- `belongs_to :user`
- `belongs_to :achievement`
- Associação polimórfica com `source` (Event, Mission, Squad, etc)

#### Callbacks:
- `set_default_earned_at` - Define `earned_at` como `Time.current` ao criar se não fornecido

#### Validações:
- Combinação de `user_id` e `achievement_id` deve ser única

#### Índices:
- Índice único em `[user_id, achievement_id]`
- Índice em `[source_type, source_id]`

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

### Sistema de Conquistas (Achievements)
- Conquistas configuráveis por guilda
- Código único por guilda
- Categorização de conquistas
- Rastreamento de quando foi conquistada
- Origem polimórfica (de qual evento/missão veio)
- Sistema ativo/inativo para conquistas legadas
- Método helper `grant_achievement` no User

### Sistema de Eventos
- Criação e gerenciamento de eventos da guilda
- Sistema de RSVP (confirmação de presença)
- Rastreamento de participação
- Recompensas por participação
- Status de evento (agendado, completo, cancelado)

### Sistema de Missões
- Missões semanais recorrentes
- Sistema de submissão de missões
- Rastreamento por semana (ISO 8601)
- Recompensas configuráveis (XP e moeda)
- Respostas em formato JSON

### Gamificação
- Pontos de XP
- Moeda virtual
- Sistema de conquistas
- Certificados
- Recompensas por eventos e missões

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
├── has_many Missions (Missões)
├── has_many Events (Eventos)
├── has_many Achievements (Conquistas)
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
├── has_many EventParticipations
├── has_many Events (through EventParticipations)
├── has_many MissionSubmissions
├── has_many Missions (through MissionSubmissions)
├── has_many UserAchievements
├── has_many Achievements (through UserAchievements)
└── has_many AuditLogs

Squad (Esquadrão)
├── belongs_to Guild
├── belongs_to Leader (User)
└── has_many Users (membros)

UserRole (Cargo do Usuário)
├── belongs_to User
└── belongs_to Role

Achievement (Conquista)
├── belongs_to Guild
├── has_many UserAchievements
└── has_many Users (through UserAchievements)

UserAchievement (Conquista do Usuário)
├── belongs_to User
├── belongs_to Achievement
└── belongs_to Source (polimórfico: Event, Mission, etc)

Event (Evento)
├── belongs_to Guild
├── belongs_to Creator (User)
├── has_many EventParticipations
└── has_many Users (through EventParticipations)

EventParticipation (Participação em Evento)
├── belongs_to Event
└── belongs_to User

Mission (Missão)
├── belongs_to Guild
├── has_many MissionSubmissions
└── has_many Users (through MissionSubmissions)

MissionSubmission (Submissão de Missão)
├── belongs_to Mission
└── belongs_to User

AuditLog (Log de Auditoria)
├── belongs_to User (opcional)
└── belongs_to Guild (opcional)
```
├── has_many UserRoles
├── has_many Roles (through UserRoles)
├── has_one Squad (como líder)
├── has_many EventParticipations
├── has_many Events (through EventParticipations)
├── has_many MissionSubmissions
├── has_many Missions (through MissionSubmissions)
└── has_many AuditLogs

Squad (Esquadrão)
├── belongs_to Guild
├── belongs_to Leader (User)
└── has_many Users (membros)

UserRole (Cargo do Usuário)
├── belongs_to User
└── belongs_to Role

Event (Evento)
├── belongs_to Guild
├── belongs_to Creator (User)
├── has_many EventParticipations
└── has_many Users (through EventParticipations)

EventParticipation (Participação em Evento)
├── belongs_to Event
└── belongs_to User

Mission (Missão)
├── belongs_to Guild
├── has_many MissionSubmissions
└── has_many Users (through MissionSubmissions)

MissionSubmission (Submissão de Missão)
├── belongs_to Mission
└── belongs_to User

AuditLog (Log de Auditoria)
├── belongs_to User (opcional)
└── belongs_to Guild (opcional)
```

---

## 🧪 Testes

Testes unitários foram implementados para todos os modelos em:
- `test/models/guild_test.rb` (7 testes)
- `test/models/role_test.rb` (7 testes)
- `test/models/user_test.rb` (11 testes)
- `test/models/squad_test.rb` (8 testes)
- `test/models/user_role_test.rb` (11 testes)
- `test/models/audit_log_test.rb` (15 testes)
- `test/models/event_test.rb` (14 testes)
- `test/models/event_participation_test.rb` (13 testes)
- `test/models/mission_test.rb` (14 testes)
- `test/models/mission_submission_test.rb` (12 testes)
- `test/models/achievement_test.rb` (11 testes)
- `test/models/user_achievement_test.rb` (12 testes)

**Total: 155 testes** (todos passando ✅)

Cada teste cobre:
- ✅ Validações de presença e formato
- ✅ Relacionamentos entre modelos
- ✅ Métodos customizados e callbacks
- ✅ Scopes e queries
- ✅ Comportamento de dependent destroy/nullify/cascade
- ✅ Enums e estados
- ✅ Validações numéricas
- ✅ Validações de unicidade (simples e com scope)
- ✅ Associações polimórficas

---

## 🗄️ Migrações de Banco de Dados

As seguintes migrações foram criadas:
1. `20260113144810_create_guilds.rb` - Tabela de guildas
2. `20260113145829_create_roles.rb` - Tabela de cargos
3. `20260113149538_create_users.rb` - Tabela de usuários
4. `20260113152640_create_user_roles.rb` - Tabela de relacionamento user-role
5. `20260113154808_create_squads.rb` - Tabela de esquadrões
6. `20260113157933_add_squad_to_user.rb` - Adiciona squad_id aos usuários
7. `20260113158934_create_audit_logs.rb` - Tabela de logs de auditoria
8. `20260113163530_create_events.rb` - Tabela de eventos
9. `20260113164038_create_event_participations.rb` - Tabela de participações em eventos
10. `20260113164804_create_missions.rb` - Tabela de missões
11. `20260113165554_create_mission_submissions.rb` - Tabela de submissões de missões
12. `20260113173755_create_active_storage_tables.rb` - Tabelas para anexos (emblemas)
13. `20260113174018_change_foreign_keys_on_events_and_squads.rb` - Adiciona cascade em FKs
14. `20260113174142_add_cascade_to_event_participations.rb` - Adiciona cascade em mais FKs
15. `20260113174257_change_audit_logs_foreign_keys.rb` - Configura nullify em audit_logs
16. `20260113182143_create_achievements.rb` - Tabela de conquistas
17. `20260113182402_create_user_achievements.rb` - Tabela de conquistas dos usuários
18. `20260113194307_add_cascade_to_achievements_foreign_keys.rb` - Adiciona cascade em conquistas

### Estratégia de Foreign Keys:
- **CASCADE**: Usado em relacionamentos onde a destruição do pai deve destruir os filhos
  - Guild → Users, Roles, Squads, Missions, Events, Achievements
  - Event → EventParticipations
  - Mission → MissionSubmissions
  - Achievement → UserAchievements
  - User → Events (como creator), Squads (como leader), UserAchievements
  
- **NULLIFY**: Usado em relacionamentos opcionais ou de auditoria
  - User → Squad (membership)
  - User/Guild → AuditLogs (mantém histórico)

---

## 📝 Próximos Passos

- [ ] Implementar controllers e rotas
- [ ] Adicionar views para gerenciamento
- [ ] Implementar autenticação OAuth com Discord
- [ ] Criar dashboard de gamificação com conquistas
- [ ] Adicionar notificações de eventos e missões
- [ ] Implementar sistema de recompensas automáticas
- [ ] Sistema de níveis baseado em XP
- [ ] Leaderboards de conquistas por guilda
- [ ] Adicionar validações de negócio mais complexas
- [ ] Implementar webhooks do Discord
- [ ] Adicionar testes de integração

---

## 🔒 Segurança

- Tokens de acesso são armazenados criptografados
- Logs de auditoria rastreiam todas as ações importantes
- Sistema de permissões baseado em cargos
- Validações de unicidade para prevenir duplicatas
- Foreign keys configuradas adequadamente para integridade de dados
- Índices únicos compostos para garantir integridade referencial
