# Configuração do Login via Discord

## ⚠️ IMPORTANTE: Restrição de Acesso

**Apenas usuários que pertencem a servidores Discord configurados na aplicação podem fazer login.**

Antes de permitir que usuários façam login, você deve:
1. Cadastrar os servidores Discord autorizados como guilds na aplicação
2. Obter o Discord Guild ID do servidor
3. Criar a guild usando o comando rake ou via código

Veja [GUILDS_DISCORD.md](GUILDS_DISCORD.md) para instruções completas.

## Configurando as Credenciais do Discord

### 1. Criar Aplicação no Discord Developer Portal

1. Acesse https://discord.com/developers/applications
2. Clique em "New Application"
3. Dê um nome à sua aplicação
4. Vá para a seção "OAuth2"
5. Adicione a URL de redirect:
   - Desenvolvimento: `http://localhost:3000/auth/discord/callback`
   - Produção: `https://seudominio.com/auth/discord/callback`

### 2. Configurar Credenciais no Rails

Execute o seguinte comando para editar as credenciais:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Adicione as seguintes informações:

```yaml
discord:
  client_id: SEU_CLIENT_ID_AQUI
  client_secret: SEU_CLIENT_SECRET_AQUI
```

Salve e feche o arquivo.

### 3. Instalar as Gems

Se ainda não instalou, execute:

```bash
bundle install
```

### 4. Reiniciar o Servidor

```bash
bin/rails restart
```

## Como Usar

### Links de Login/Logout

Para adicionar um botão de login em qualquer view:

```erb
<%= link_to "Entrar com Discord", discord_login_path, class: "btn btn-primary" %>
```

Para logout:

```erb
<%= button_to "Sair", logout_path, method: :delete, class: "btn btn-secondary" %>
```

### Protegendo Rotas

No controller que deseja proteger:

```ruby
class MeuController < ApplicationController
  before_action :require_login  # Requer login
  # ou
  before_action :require_admin  # Requer admin
end
```

### Verificando Login nas Views

```erb
<% if logged_in? %>
  <p>Olá, <%= current_user.discord_username %>!</p>
<% else %>
  <%= link_to "Fazer Login", discord_login_path %>
<% end %>
```

### Helpers Disponíveis

- `current_user` - Retorna o usuário logado ou nil
- `logged_in?` - Retorna true se há usuário logado
- `require_login` - Redireciona para root se não logado
- `require_admin` - Redireciona para root se não for admin

## Rotas Disponíveis

- `GET /auth/discord` - Inicia o processo de login
- `GET /auth/discord/callback` - Callback do Discord após autenticação
- `DELETE /logout` - Realiza logout do usuário
- `GET /auth/failure` - Tratamento de falhas na autenticação

## Escopos do Discord

A aplicação solicita os seguintes escopos:
- `identify` - Informações básicas do usuário (username, avatar)
- `guilds` - Lista de servidores do usuário (necessário para associar à guild correta)
- `email` - Email do usuário

**Importante**: O escopo `guilds` é essencial para que a aplicação possa associar automaticamente o usuário à guild correta baseada nos servidores Discord que ele participa.

## Associação de Guilds

Durante o login, o sistema:

1. Obtém a lista de servidores Discord do usuário
2. **Verifica se o usuário pertence a pelo menos um servidor configurado na aplicação**
3. **Se não pertencer a nenhum servidor configurado, o login é negado**
4. Se pertencer, associa o usuário à guild correspondente encontrada
5. Em logins subsequentes, atualiza a guild do usuário se necessário

### Configurando Servidores Autorizados

**ANTES** de permitir que usuários façam login, você precisa cadastrar as guilds:

```bash
# Obter o Discord Guild ID:
# 1. No Discord, vá em Configurações de Usuário > Avançado
# 2. Ative "Modo Desenvolvedor"
# 3. Clique com botão direito no servidor > "Copiar ID do Servidor"

# Criar guild correspondente ao servidor
bin/rails discord:create_guild[123456789012345678,"Nome do Servidor"]

# Verificar guilds cadastradas
bin/rails discord:list_guilds
```

### Mensagem de Erro

Se um usuário tentar fazer login sem pertencer a um servidor configurado, receberá:

> "Acesso negado. Você precisa estar em um servidor Discord autorizado para fazer login."

Para mais informações sobre gerenciamento de guilds, veja [GUILDS_DISCORD.md](GUILDS_DISCORD.md).

## Segurança

- Em produção, apenas requisições POST são permitidas para iniciar OAuth
- CSRF protection está ativo
- Logs de auditoria são criados em login/logout
- Session-based authentication

## Troubleshooting

### Erro "Acesso negado. Você precisa estar em um servidor Discord autorizado"

Este erro ocorre quando:
1. O usuário não pertence a nenhum servidor Discord configurado na aplicação
2. Nenhuma guild foi cadastrada ainda

**Solução:**
```bash
# 1. Obter o ID do servidor Discord
# No Discord: Configurações > Avançado > Modo Desenvolvedor (ativar)
# Clique direito no servidor > Copiar ID do Servidor

# 2. Cadastrar o servidor como guild
bin/rails discord:create_guild[ID_DO_SERVIDOR,"Nome do Servidor"]

# 3. Verificar se foi criado
bin/rails discord:list_guilds
```

### Erro de Credenciais

Se você receber erro de credenciais não configuradas:
1. Verifique se as credenciais estão no arquivo correto
2. Reinicie o servidor Rails
3. Verifique se o client_id e client_secret estão corretos

### Erro de Redirect URI Mismatch

1. Verifique se a URL no Discord Developer Portal está exatamente igual à configurada
2. Certifique-se de incluir `/auth/discord/callback`

### Usuário não sendo criado

1. Verifique se existe pelo menos um Guild no banco de dados
2. O modelo User requer um guild_id, você pode modificar isso no método `find_or_create_from_discord`
