# Exemplos Práticos de Uso

## Exemplo 1: Configuração Básica (Comunidade Aberta)

Sua comunidade está começando e quer dar acesso a todos do servidor:

```bash
# 1. Criar guild
bin/rails discord:create_guild[123456789012345678,"Minha Comunidade"]

# 2. Não configure cargo requerido
# ✅ Pronto! Todos do servidor podem acessar
```

## Exemplo 2: Comunidade com Membros Verificados

Você quer que apenas membros verificados tenham acesso:

```bash
# 1. No Discord, criar cargo "Membro Verificado"
# 2. Copiar ID do cargo: 987654321098765432

# 3. Configurar bot token (uma vez)
EDITOR="code --wait" bin/rails credentials:edit
```

Adicionar:
```yaml
discord:
  client_id: seu_client_id
  client_secret: seu_client_secret
  bot_token: seu_bot_token  # Adicione esta linha
```

```bash
# 4. Adicionar bot ao servidor Discord
# Use URL do OAuth2 Generator no Discord Developer Portal

# 5. Configurar cargo requerido
bin/rails discord:set_required_role[1,987654321098765432,"Membro Verificado"]

# 6. Atualizar acesso dos usuários existentes
bin/rails discord:update_guild_access[1]
```

## Exemplo 3: Múltiplas Guilds com Regras Diferentes

```bash
# Guild 1: Comunidade aberta
bin/rails discord:create_guild[111111111111111111,"Comunidade A"]
# Sem cargo requerido = acesso livre

# Guild 2: Comunidade restrita
bin/rails discord:create_guild[222222222222222222,"Comunidade B"]
bin/rails discord:set_required_role[2,888888888888888888,"Elite"]
# Apenas membros com cargo "Elite"

# Verificar configuração
bin/rails discord:list_guilds
```

## Exemplo 4: Protegendo Controllers

### Opção 1: Proteger controller inteiro

```ruby
class MissionsController < ApplicationController
  before_action :require_guild_access  # Todos os métodos requerem acesso
  
  def index
    @missions = Mission.all
  end
  
  def show
    @mission = Mission.find(params[:id])
  end
end
```

### Opção 2: Proteger ações específicas

```ruby
class EventsController < ApplicationController
  before_action :require_guild_access, only: [:create, :update, :destroy]
  
  def index
    # Qualquer usuário logado pode ver lista
    @events = Event.all
  end
  
  def create
    # Apenas com acesso à guild
    @event = Event.new(event_params)
    # ...
  end
end
```

### Opção 3: Conteúdo condicional

```ruby
class DashboardController < ApplicationController
  before_action :require_login
  
  def index
    @user = current_user
    
    if has_guild_access?
      @missions = Mission.available
      @events = Event.upcoming
    else
      # Mostrar conteúdo limitado
      @missions = []
      @events = []
    end
  end
end
```

## Exemplo 5: Views Condicionais

### Layout do site

```erb
<!-- app/views/layouts/application.html.erb -->
<nav>
  <% if logged_in? %>
    <p>Olá, <%= current_user.discord_username %>!</p>
    
    <% if has_guild_access? %>
      <!-- Menu completo para membros com acesso -->
      <%= link_to "Missões", missions_path %>
      <%= link_to "Eventos", events_path %>
      <%= link_to "Rankings", rankings_path %>
    <% else %>
      <!-- Menu limitado -->
      <span class="text-yellow-600">⚠️ Acesso Limitado</span>
      <%= link_to "Ver Requisitos", restricted_access_path %>
    <% end %>
    
    <%= button_to "Sair", logout_path, method: :delete %>
  <% else %>
    <%= link_to "Login com Discord", discord_login_path %>
  <% end %>
</nav>
```

### Página com conteúdo misto

```erb
<!-- app/views/home/index.html.erb -->
<h1>Bem-vindo!</h1>

<!-- Conteúdo público -->
<section>
  <h2>Sobre Nós</h2>
  <p>Nossa comunidade...</p>
</section>

<!-- Conteúdo para membros -->
<% if has_guild_access? %>
  <section class="members-only">
    <h2>Área dos Membros</h2>
    <div class="grid">
      <%= render @missions %>
    </div>
  </section>
<% elsif logged_in? %>
  <div class="bg-yellow-50 p-4 rounded">
    <p>Você precisa do cargo de <strong><%= current_user.guild.required_discord_role_name %></strong> para acessar o conteúdo exclusivo.</p>
    <%= link_to "Saiba Mais", restricted_access_path, class: "btn" %>
  </div>
<% end %>
```

## Exemplo 6: API/JSON Responses

```ruby
class Api::MissionsController < ApplicationController
  before_action :require_guild_access
  
  def index
    missions = Mission.all
    render json: missions
  rescue => e
    render json: { error: "Acesso negado" }, status: :forbidden
  end
end
```

## Exemplo 7: Atualização em Massa de Acesso

Depois de adicionar novos membros ao cargo no Discord:

```bash
# Atualizar todos os usuários da guild
bin/rails discord:update_guild_access[1]
```

Ou criar um job para fazer isso automaticamente:

```ruby
# app/jobs/update_guild_access_job.rb
class UpdateGuildAccessJob < ApplicationJob
  queue_as :default

  def perform(guild_id)
    guild = Guild.find(guild_id)
    
    guild.users.find_each do |user|
      has_access = User.check_guild_role_access(guild, user.discord_id)
      user.update(has_guild_access: has_access)
    end
  end
end
```

Agendar:
```ruby
# config/schedule.rb (com gem whenever)
every 1.hour do
  Guild.find_each do |guild|
    UpdateGuildAccessJob.perform_later(guild.id)
  end
end
```

## Exemplo 8: Notificação de Mudança de Acesso

```ruby
# app/models/user.rb
after_update :notify_access_change

def notify_access_change
  if saved_change_to_has_guild_access?
    if has_guild_access?
      # Usuário ganhou acesso
      UserMailer.access_granted(self).deliver_later
    else
      # Usuário perdeu acesso
      UserMailer.access_revoked(self).deliver_later
    end
  end
end
```

## Exemplo 9: Console Rails

```ruby
# Verificar status de um usuário
user = User.find_by(discord_username: "John")
user.has_guild_access?  # => true/false

# Verificar manualmente se usuário tem cargo
guild = Guild.first
User.check_guild_role_access(guild, user.discord_id)

# Forçar atualização de acesso
user.update(has_guild_access: User.check_guild_role_access(user.guild, user.discord_id))

# Listar usuários sem acesso
User.where(has_guild_access: false)

# Contar usuários por guild
Guild.all.each do |guild|
  total = guild.users.count
  with_access = guild.users.where(has_guild_access: true).count
  puts "#{guild.name}: #{with_access}/#{total} com acesso"
end
```

## Exemplo 10: Migração de Guild Aberta para Restrita

```bash
# 1. Verificar estado atual
bin/rails discord:list_guilds

# Guilds cadastradas:
#   ID: 1
#   Nome: Minha Comunidade
#   Usuários: 50
#   ✓ Acesso livre (sem cargo requerido)

# 2. Criar cargo no Discord e obter ID

# 3. Configurar cargo requerido
bin/rails discord:set_required_role[1,999999999999999999,"Membro Ativo"]

# 4. Atualizar todos os usuários
bin/rails discord:update_guild_access[1]

# 5. Verificar resultado
bin/rails discord:list_guilds

# Guilds cadastradas:
#   ID: 1
#   Nome: Minha Comunidade
#   Usuários: 50
#   ⚠️  Cargo Requerido: Membro Ativo (999999999999999999)
#      Usuários com acesso: 32 de 50

# 6. Comunicar aos 18 usuários sem acesso sobre como obter o cargo
```

## Exemplo 11: Testes

```ruby
# test/integration/access_control_test.rb
require "test_helper"

class AccessControlTest < ActionDispatch::IntegrationTest
  test "usuario sem acesso vê página restrita" do
    user = users(:without_access)
    
    # Simula login
    post auth_discord_callback_path, params: { ... }
    
    # Tenta acessar recurso protegido
    get missions_path
    
    # Deve redirecionar para página restrita
    assert_redirected_to restricted_access_path
  end
  
  test "usuario com acesso pode ver recursos" do
    user = users(:with_access)
    
    post auth_discord_callback_path, params: { ... }
    get missions_path
    
    assert_response :success
  end
end
```

## Dicas Importantes

1. **Sempre teste** em ambiente de desenvolvimento primeiro
2. **Comunique mudanças** aos usuários antes de ativar restrições
3. **Monitore logs** de acesso para identificar problemas
4. **Configure bot token** corretamente para verificação funcionar
5. **Atualize acesso** periodicamente ou após mudanças de cargos no Discord
