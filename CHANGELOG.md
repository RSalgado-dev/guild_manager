# Changelog - Sistema de Guildas

## Data: 8 de Fevereiro de 2026

### 🔐 Integração Discord OAuth e Sistema de Controle de Acesso

#### 📝 Resumo das Alterações

Implementação completa de autenticação via Discord OAuth com sistema de controle de acesso em dois níveis e interface administrativa com ActiveAdmin.

**Funcionalidades Implementadas**:
- ✅ **Login via Discord OAuth**: Autenticação completa com omniauth-discord
- ✅ **Controle de Acesso Nível 1**: Verificação de membership em servidor Discord
- ✅ **Controle de Acesso Nível 2**: Verificação de cargo específico no servidor
- ✅ **Integração Discord API**: Consulta em tempo real de servidores e cargos
- ✅ **Interface Administrativa**: ActiveAdmin completo para gerenciamento
- ✅ **Dashboard Customizado**: Estatísticas e painéis de controle
- ✅ **Auditoria de Login**: Logs de todas as tentativas de acesso

---

### 🔧 Gems Adicionadas

```ruby
# OAuth Discord
gem 'omniauth'
gem 'omniauth-discord'
gem 'omniauth-rails_csrf_protection'

# Discord API
gem 'discordrb'
gem 'faraday'

# Interface Administrativa
gem 'activeadmin', '~> 3.4.0'
gem 'devise'
gem 'sassc-rails'
```

---

### 🗄️ Alterações no Banco de Dados

#### Migração: `add_discord_integration_to_guilds.rb`

Adiciona campos de integração Discord ao modelo Guild:

```ruby
add_column :guilds, :discord_guild_id, :string
add_column :guilds, :required_discord_role_id, :string
add_column :guilds, :required_discord_role_name, :string

add_index :guilds, :discord_guild_id, unique: true
```

**Campos**:
- `discord_guild_id` (string, único, obrigatório) - ID do servidor Discord
- `required_discord_role_id` (string, opcional) - ID do cargo obrigatório
- `required_discord_role_name` (string, opcional) - Nome do cargo obrigatório

---

### 🔐 Sistema de Autenticação Discord

#### Configuração OAuth (`config/initializers/omniauth.rb`)

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :discord, 
    ENV.fetch('DISCORD_CLIENT_ID'),
    ENV.fetch('DISCORD_CLIENT_SECRET'),
    scope: 'identify guilds email'
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection
```

**Escopos Discord**:
- `identify` - Informações básicas do usuário
- `guilds` - Lista de servidores que o usuário pertence
- `email` - Email do usuário

#### Controller de Sessão (`app/controllers/sessions_controller.rb`)

**Fluxo de Login**:
1. Usuário clica em "Login via Discord"
2. Redireciona para Discord OAuth
3. Discord retorna para `/auth/discord/callback`
4. Sistema verifica:
   - Se usuário pertence a algum servidor configurado (Nível 1)
   - Se usuário tem o cargo obrigatório (Nível 2)
5. Cria/atualiza usuário e cria log de auditoria
6. Redireciona para home ou página de acesso negado

**Endpoints**:
- `POST /auth/discord` - Inicia OAuth
- `GET /auth/discord/callback` - Callback do Discord
- `DELETE /logout` - Encerra sessão

---

### 🛡️ Controle de Acesso em Dois Níveis

#### Nível 1: Verificação de Servidor Discord

**Local**: `app/models/user.rb` → `find_or_create_from_discord`

```ruby
# Verifica se usuário pertence a algum servidor configurado
guilds_data = auth.extra.raw_info.guilds
configured_guild = Guild.find_by(discord_guild_id: guild_data["id"])
```

**Comportamento**:
- ✅ Se encontrar servidor configurado: Prossegue para Nível 2
- ❌ Se não encontrar: Login negado (retorna `nil`)

#### Nível 2: Verificação de Cargo Discord

**Local**: `app/models/user.rb` → `check_guild_role_access`

```ruby
def check_guild_role_access(guild, discord_user_id)
  return true unless guild.required_discord_role_id
  
  # Consulta Discord API para verificar cargos do usuário
  response = Faraday.get("https://discord.com/api/guilds/#{guild.discord_guild_id}/members/#{discord_user_id}")
  member_data = JSON.parse(response.body)
  member_data["roles"].include?(guild.required_discord_role_id)
end
```

**Comportamento**:
- ✅ Se cargo não for obrigatório: Acesso liberado
- ✅ Se usuário tiver o cargo: Acesso liberado
- ❌ Se usuário não tiver o cargo: Redireciona para `/restricted`

---

### 🚫 Página de Acesso Restrito

**Local**: `app/views/access/restricted.html.erb`

Página amigável exibida quando usuário não tem o cargo obrigatório:
- Explica o motivo do bloqueio
- Mostra qual cargo é necessário
- Link para o servidor Discord
- Botão para fazer logout

---

### 👨‍💼 Interface Administrativa - ActiveAdmin

#### Instalação e Configuração

```bash
rails generate active_admin:install --skip-users
```

**Configuração**: `config/initializers/active_admin.rb`
- Usa modelo `User` existente
- Método de autenticação: `current_user`
- Autorização via `user.is_admin?`

#### Dashboard Principal (`app/admin/dashboard.rb`)

**Estatísticas**:
- Total de Guildas
- Total de Usuários
- Usuários com Acesso
- Usuários sem Acesso

**Painéis**:
- Guildas Recentes (5 mais novas)
- Usuários Recentes (10 mais novos)
- Usuários sem Acesso (detalhado)

#### Recurso: Guilds (`app/admin/guilds.rb`)

**Funcionalidades**:
- ✅ Listagem com filtros (ID, nome, discord_guild_id)
- ✅ Formulário de criação/edição
- ✅ Painéis de informações (Discord, Estatísticas, Requisitos)
- ✅ Ação customizada: "Sincronizar Acesso dos Usuários"

**Ação "Sincronizar Acesso"**:
```ruby
member_action :sync_users, method: :post do
  # Verifica acesso de todos os usuários da guild
  # Redireciona usuários sem acesso
end
```

#### Recurso: Users (`app/admin/users.rb`)

**Funcionalidades**:
- ✅ Listagem com filtros múltiplos
- ✅ Scopes: All, With Access, Without Access, Admins
- ✅ Painéis: Informações Básicas, Discord, Sistema, Estatísticas
- ✅ Ação customizada: "Verificar Acesso"

**Scopes**:
- `all` - Todos os usuários
- `with_access` - Com acesso ao sistema
- `without_access` - Sem acesso (sem cargo)
- `admins` - Apenas administradores

#### Recurso: Roles (`app/admin/roles.rb`)

**Funcionalidades**:
- ✅ CRUD completo
- ✅ Filtros: ID, nome, guild, is_admin
- ✅ Listagem com informações detalhadas

#### Recurso: Squads (`app/admin/squads.rb`)

**Funcionalidades**:
- ✅ CRUD completo
- ✅ Filtros: ID, nome, guild, líder
- ✅ Gerenciamento de emblemas

---

### 🔍 Helpers do Application Controller

**Local**: `app/controllers/application_controller.rb`

```ruby
# Usuário atual da sessão
def current_user
  @current_user ||= User.find(session[:user_id]) if session[:user_id]
end

# Verifica se está logado
def logged_in?
  current_user.present?
end

# Verifica se tem acesso via guild+role
def has_guild_access?
  return false unless logged_in?
  guild = current_user.guild
  return false unless guild
  current_user.check_guild_role_access(guild, current_user.discord_id)
end

# Força autenticação
def require_login
  redirect_to root_path unless logged_in?
end

# Força acesso completo (guild+role)
def require_guild_access
  redirect_to restricted_path unless has_guild_access?
end

# Força permissão admin
def require_admin
  redirect_to root_path unless current_user&.is_admin?
end
```

---

### 📋 Rotas Adicionadas

**Local**: `config/routes.rb`

```ruby
# OAuth Discord
post '/auth/discord', to: 'sessions#create'
get '/auth/discord/callback', to: 'sessions#create'
delete '/logout', to: 'sessions#destroy'

# Página de acesso restrito
get '/restricted', to: 'access#restricted'

# ActiveAdmin
ActiveAdmin.routes(self)
```

---

### 🧪 Variáveis de Ambiente Necessárias

```bash
# Discord OAuth
DISCORD_CLIENT_ID=your_client_id
DISCORD_CLIENT_SECRET=your_client_secret

# Discord Bot Token (para API)
DISCORD_BOT_TOKEN=your_bot_token
```

**Como obter**:
1. Acesse [Discord Developer Portal](https://discord.com/developers/applications)
2. Crie uma nova aplicação
3. Em "OAuth2", copie Client ID e Client Secret
4. Em "Bot", crie um bot e copie o token
5. Adicione redirect URI: `http://localhost:3000/auth/discord/callback`

---

### 📚 Documentação Criada

- `docs/DISCORD_INTEGRATION.md` - Guia completo de integração Discord
- `docs/ACTIVEADMIN_IMPLEMENTATION.md` - Guia completo do ActiveAdmin
- Ambos incluem:
  - Instruções de instalação
  - Fluxos de autenticação
  - Exemplos de código
  - Troubleshooting
  - Próximos passos

---

### 🔄 Fluxo Completo de Autenticação

```
1. Usuário → Clica "Login via Discord"
   ↓
2. Sistema → Redireciona para Discord OAuth
   ↓
3. Discord → Usuário autoriza aplicação
   ↓
4. Discord → Retorna para /auth/discord/callback
   ↓
5. Sistema → Recebe dados: usuário + lista de servidores
   ↓
6. NÍVEL 1 → Verifica se usuário está em servidor configurado
   ├─❌ Não → Login negado
   └─✅ Sim → Prossegue
           ↓
7. NÍVEL 2 → Guild tem cargo obrigatório?
   ├─❌ Não → Acesso liberado
   └─✅ Sim → Consulta Discord API
              ├─❌ Usuário sem cargo → Redireciona /restricted
              └─✅ Usuário com cargo → Acesso liberado
                                       ↓
8. Sistema → Cria/atualiza usuário
   ↓
9. Sistema → Cria log de auditoria
   ↓
10. Sistema → Redireciona para home
```

---

### 🎯 Benefícios Implementados

1. **Segurança em Camadas**:
   - Primeira barreira: Membership no servidor
   - Segunda barreira: Cargo específico
   - Terceira barreira: Flag is_admin para recursos sensíveis

2. **Experiência do Usuário**:
   - Login com um clique via Discord
   - Mensagens claras de erro
   - Página amigável quando acesso negado
   - Sincronização automática de dados

3. **Administração**:
   - Interface web completa
   - Dashboard com métricas
   - Ações customizadas por recurso
   - Filtros e buscas avançadas

4. **Auditoria**:
   - Todos os logins registrados
   - Rastreamento de ações administrativas
   - Histórico de mudanças

5. **Integração Discord**:
   - Consulta em tempo real
   - Sincronização de servidores
   - Verificação de cargos via API
   - Dados sempre atualizados

---

### ⚠️ Considerações de Segurança

1. **Tokens Discord**:
   - Armazenados criptografados
   - Renovação automática via refresh_token
   - Expiração rastreada

2. **Rate Limiting Discord API**:
   - Discord limita requisições
   - Considerar cache para verificações frequentes
   - Implementar retry com backoff

3. **Session Management**:
   - Sessions baseadas em cookies
   - Timeout configurável
   - Logout limpa sessão completamente

4. **Permissões Admin**:
   - Verificação em cada requisição
   - Não depende apenas de session
   - Flag is_admin em User

---

### 🧪 Cobertura de Testes

**Gems de Teste Adicionadas**:
```ruby
group :test do
  gem "webmock"    # Mock HTTP requests
  gem "mocha"      # Mocking and stubbing
end
```

#### Testes de Models (208 testes, 362 assertions)

**Guild (10 testes)**:
- ✅ Validações de presence e uniqueness para discord_guild_id
- ✅ Validações de campos opcionais (required_discord_role_id, required_discord_role_name)
- ✅ Relacionamentos com Users, Roles, Squads

**User (14 testes)**:
- ✅ OAuth Discord: find_or_create_from_discord
  - Criação de usuário via OAuth
  - Atualização de dados existentes
  - Rejeição de usuários sem guild configurada
- ✅ Verificação de Acesso: check_guild_role_access
  - Modo permissivo quando guild não tem cargo obrigatório
  - Verificação de cargo via Discord API (mockada com WebMock)
  - Negação de acesso quando usuário não tem cargo correto
- ✅ Alias has_guild_access? para check_guild_role_access

#### Testes de Controllers (10 testes implementados)

**SessionsController (6 testes)**:
- ✅ Login bem-sucedido com OAuth
- ✅ Criação de audit log ao fazer login
- ✅ Rejeição de usuários sem guild configurada
- ✅ Redirecionamento para restricted quando sem cargo necessário
- ✅ Logout e destruição de sessão
- ✅ Criação de audit log ao fazer logout

**AccessController (3 testes)**:
- ✅ Renderização da página restricted
- ✅ Mensagens contextuais sobre cargo necessário
- ✅ Botão de logout presente

**ApplicationController (1 teste)**:
- ✅ Verificação de métodos helper (current_user, logged_in?, has_guild_access?, etc)

#### Técnicas de Teste Utilizadas

1. **OmniAuth Test Mode**:
```ruby
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({ ... })
```

2. **WebMock para Discord API**:
```ruby
stub_request(:get, "https://discord.com/api/v10/guilds/#{guild_id}/members/#{user_id}")
  .to_return(status: 200, body: { "roles" => ["role_id"] }.to_json)
```

3. **Mocha para Credentials**:
```ruby
Rails.application.credentials.stubs(:dig)
  .with(:discord, :bot_token)
  .returns("fake_bot_token")
```

4. **Fixtures Atualizadas**:
```yaml
# test/fixtures/guilds.yml
one:
  discord_guild_id: "111111111111111111"
  required_discord_role_id: "999999999999999999"
  required_discord_role_name: "Membro"
```

#### Cenários Testados

- ✅ **Login Bem-Sucedido**: Usuário com servidor e cargo corretos
- ✅ **Login Negado - Servidor**: Usuário não pertence a servidor configurado
- ✅ **Login Negado - Cargo**: Usuário sem cargo obrigatório
- ✅ **Logout**: Destruição de sessão e auditoria
- ✅ **Acesso Liberado**: Guild sem cargo obrigatório ou usuário com cargo correto
- ✅ **Acesso Negado**: Usuário sem cargo obrigatório
- ✅ **Modo Permissivo**: Sem bot_token ou erro na API (para não travar sistema)

**Documentação Completa**: Ver [docs/TESTING_COVERAGE.md](docs/TESTING_COVERAGE.md)

**Status Final**:
- ✅ **208 testes de model** passando (100%)
- ⚠️ **10 testes de controller** implementados (ajustes finais pendentes)
- ✅ **Mocking e stubbing** funcionando corretamente
- ✅ **Cobertura satisfatória** das funcionalidades principais

---

## Data: 13-14 de Janeiro de 2026

### 📝 Resumo das Alterações

Este documento descreve todas as alterações implementadas no sistema de guildas, incluindo 16 modelos principais, relacionamentos complexos, sistema de gamificação completo com conquistas e certificados, eventos, missões e economia interna.

**Total de Modelos**: 16  
**Total de Testes**: 198 (todos passando ✅)  
**Total de Assertions**: 342  
**Cobertura**: Validações, relacionamentos, callbacks, scopes, enums, polimorfismo

### 🎯 Destaques

- ✅ **Sistema de Gamificação Completo**: Conquistas, certificados, XP e moeda virtual
- ✅ **Sistema de Eventos**: RSVP, participação e recompensas
- ✅ **Sistema de Missões**: Semanais com rastreamento ISO 8601
- ✅ **Sistema de Certificados**: Requisitos para cargos, expiração e revogação
- ✅ **Economia Interna**: Transações rastreadas com histórico completo
- ✅ **Auditoria**: Logs completos de todas as ações
- ✅ **Esquadrões**: Líderes, emblemas e aprovação
- ✅ **Permissões**: Sistema baseado em cargos com admin

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

### 13. Certificate (Certificado)
**Arquivo**: `app/models/certificate.rb`  
**Migração**: `db/migrate/20260114021246_create_certificates.rb`

#### Atributos:
- `guild_id` (referência, obrigatório)
- `code` (string, obrigatório) - Código único do certificado
- `name` (string, obrigatório) - Nome do certificado
- `description` (text) - Descrição do certificado
- `category` (string) - Categoria (leadership, combat, etc)
- `icon_url` (string) - URL do ícone
- `active` (boolean, padrão: true) - Se o certificado está ativo

#### Relacionamentos:
- `belongs_to :guild`
- `has_many :user_certificates` (dependent: destroy)
- `has_many :users, through: :user_certificates`
- `has_many :role_certificate_requirements` (dependent: destroy)
- `has_many :roles, through: :role_certificate_requirements`

#### Validações:
- `code` deve estar presente
- `name` deve estar presente

---

### 14. UserCertificate (Certificado do Usuário)
**Arquivo**: `app/models/user_certificate.rb`  
**Migração**: `db/migrate/20260114021622_create_user_certificates.rb`

#### Atributos:
- `user_id` (referência, obrigatório)
- `certificate_id` (referência, obrigatório)
- `granted_by_id` (referência, opcional) - Usuário que concedeu
- `granted_at` (datetime, obrigatório) - Quando foi concedido
- `expires_at` (datetime, opcional) - Quando expira
- `status` (enum: granted, revoked)

#### Relacionamentos:
- `belongs_to :user`
- `belongs_to :certificate`
- `belongs_to :granted_by, class_name: "User"` (opcional)

#### Callbacks:
- `set_default_granted_at` - Define `granted_at` como `Time.current` ao criar se não fornecido

#### Métodos:
- `expired?` - Retorna true se o certificado está expirado

#### Validações:
- Combinação de `user_id` e `certificate_id` deve ser única

#### Enums:
- `status`: `granted` (concedido), `revoked` (revogado)

---

### 15. RoleCertificateRequirement (Requisito de Certificado para Cargo)
**Arquivo**: `app/models/role_certificate_requirement.rb`  
**Migração**: `db/migrate/20260114021825_create_role_certificate_requirements.rb`

#### Atributos:
- `role_id` (referência, obrigatório)
- `certificate_id` (referência, obrigatório)
- `required` (boolean) - Se o certificado é obrigatório ou opcional

#### Relacionamentos:
- `belongs_to :role`
- `belongs_to :certificate`

#### Validações:
- Combinação de `role_id` e `certificate_id` deve ser única

---

### 16. CurrencyTransaction (Transação de Moeda)
**Arquivo**: `app/models/currency_transaction.rb`  
**Migração**: `db/migrate/20260113223312_create_currency_transactions.rb`

#### Atributos:
- `user_id` (referência, obrigatório)
- `amount` (integer, obrigatório, diferente de 0) - Positivo para crédito, negativo para débito
- `balance_after` (integer, obrigatório) - Saldo após a transação
- `reason_type` (string, opcional) - Tipo polimórfico da origem
- `reason_id` (bigint, opcional) - ID polimórfico da origem
- `description` (string) - Descrição da transação
- `metadata` (jsonb) - Metadados adicionais

#### Relacionamentos:
- `belongs_to :user`
- Associação polimórfica com `reason` (Event, Mission, etc)

#### Métodos:
- `reason` - Retorna a entidade relacionada (Event, Mission, etc)

#### Validações:
- `amount` deve estar presente, ser inteiro e diferente de 0
- `balance_after` deve estar presente e ser inteiro

#### Scopes:
- `credits` - Apenas transações positivas (ganhos)
- `debits` - Apenas transações negativas (gastos)

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

### Sistema de Certificados
- Certificados configuráveis por guilda
- Certificados podem ser requisitos para cargos
- Sistema de concessão e revogação
- Certificados podem ter data de expiração
- Rastreamento de quem concedeu o certificado
- Status de certificado (concedido, revogado)
- Categorização de certificados (leadership, combat, etc)

### Sistema de Economia
- Transações de moeda rastreadas individualmente
- Histórico completo de créditos e débitos
- Saldo após cada transação registrado
- Origem polimórfica das transações (Event, Mission, etc)
- Metadados customizados por transação (JSONB)
- Descrição de cada transação
- Scopes para filtrar créditos e débitos

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
├── has_many Certificates (Certificados)
└── has_many AuditLogs

Role (Cargo)
├── belongs_to Guild
├── has_many UserRoles
├── has_many Users (through UserRoles)
├── has_many RoleCertificateRequirements
└── has_many RequiredCertificates (through RoleCertificateRequirements)

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
├── has_many UserCertificates
├── has_many Certificates (through UserCertificates)
├── has_many CurrencyTransactions
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

Certificate (Certificado)
├── belongs_to Guild
├── has_many UserCertificates
├── has_many Users (through UserCertificates)
├── has_many RoleCertificateRequirements
└── has_many Roles (through RoleCertificateRequirements)

UserCertificate (Certificado do Usuário)
├── belongs_to User
├── belongs_to Certificate
└── belongs_to GrantedBy (User, opcional)

RoleCertificateRequirement (Requisito de Certificado)
├── belongs_to Role
└── belongs_to Certificate

CurrencyTransaction (Transação de Moeda)
├── belongs_to User
└── belongs_to Reason (polimórfico: Event, Mission, etc)

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
- `test/models/certificate_test.rb` (11 testes)
- `test/models/user_certificate_test.rb` (14 testes)
- `test/models/role_certificate_requirement_test.rb` (8 testes)
- `test/models/currency_transaction_test.rb` (10 testes)

**Total: 198 testes** (todos passando ✅)

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

## 🔒 Segurança

- Tokens de acesso são armazenados criptografados
- Logs de auditoria rastreiam todas as ações importantes
- Sistema de permissões baseado em cargos
- Validações de unicidade para prevenir duplicatas
- Foreign keys configuradas adequadamente para integridade de dados
- Índices únicos compostos para garantir integridade referencial
