# Configuração de Ambiente - Modo Desenvolvimento

## 📋 Resumo

Este documento descreve todas as variáveis de ambiente necessárias para executar a aplicação em modo de desenvolvimento.

---

## 🔑 Variáveis Obrigatórias

### 1. Banco de Dados PostgreSQL

Estas variáveis são **obrigatórias** se você não estiver usando os valores padrão:

```bash
DATABASE_NAME=workspace_development
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
DATABASE_HOST=localhost
DATABASE_PORT=5432
```

**Valores Padrão**:
- Se não configuradas, o sistema usa os valores acima por padrão
- ✅ **Em dev containers**: Já está configurado automaticamente
- ⚠️ **Em instalação local**: Verifique suas credenciais PostgreSQL

---

### 2. Discord OAuth (via Rails Credentials)

As credenciais Discord são armazenadas de forma **criptografada** em `config/credentials.yml.enc`, **não em variáveis de ambiente**.

#### Como Configurar

**Passo 1**: Editar credentials

```bash
# Use seu editor preferido
EDITOR="code --wait" rails credentials:edit

# Ou use vim
EDITOR=vim rails credentials:edit
```

**Passo 2**: Adicionar estrutura Discord

```yaml
discord:
  client_id: "SEU_DISCORD_CLIENT_ID"
  client_secret: "SEU_DISCORD_CLIENT_SECRET"
  bot_token: "SEU_DISCORD_BOT_TOKEN"  # OPCIONAL em dev
```

**Passo 3**: Salvar e fechar o editor

O arquivo será automaticamente criptografado usando `config/master.key`.

⚠️ **IMPORTANTE**: Nunca commite o arquivo `master.key`!

---

## 🎮 Obtendo Credenciais Discord

### 1. Criar Aplicação Discord

1. Acesse [Discord Developer Portal](https://discord.com/developers/applications)
2. Clique em **"New Application"**
3. Dê um nome (ex: "Sistema de Guildas Dev")
4. Clique em **"Create"**

### 2. Configurar OAuth2

1. No menu lateral, clique em **"OAuth2"** > **"General"**
2. **Client ID**: Copie e guarde
3. **Client Secret**: 
   - Clique em "Reset Secret"
   - Copie e guarde (só aparece uma vez!)
4. **Redirects**:
   - Clique em "Add Redirect"
   - Adicione: `http://localhost:3000/auth/discord/callback`
   - Clique em "Save Changes"

### 3. Configurar Escopos OAuth2

Na seção **"OAuth2 URL Generator"**:
- Selecione scopes:
  - ✅ `identify` - Informações básicas do usuário
  - ✅ `email` - Email do usuário
  - ✅ `guilds` - Lista de servidores
- Copie a URL gerada para testar manualmente se necessário

### 4. Criar Bot (OPCIONAL em Dev)

⚠️ **O bot_token é opcional em desenvolvimento**. Sem ele, o sistema opera em "modo permissivo" (todos têm acesso).

Se você quiser testar o controle de acesso  baseado em cargos Discord:

1. No menu lateral, clique em **"Bot"**
2. Clique em **"Add Bot"** (se não existir)
3. **Token**:
   - Clique em "Reset Token"
   - Copie e guarde (só aparece uma vez!)
4. **Privileged Gateway Intents**:
   - ✅ Ative "SERVER MEMBERS INTENT"
   - Clique em "Save Changes"

### 5. Adicionar Bot ao Servidor (se configurou bot)

1. Vá em **"OAuth2"** > **"URL Generator"**
2. Selecione:
   - Scopes: ✅ `bot`
   - Bot Permissions: ✅ `Read Messages/View Channels`
3. Copie a URL gerada
4. Cole no navegador e adicione o bot ao seu servidor de testes

---

## 📝 Arquivo .env (Opcional)

Para facilitar, você pode criar um arquivo `.env` na raiz do projeto:

```bash
# Copiar o exemplo
cp .env.example .env

# Editar com suas configurações
nano .env
```

**Exemplo de `.env` mínimo**:

```bash
# Banco de dados (se diferente do padrão)
DATABASE_PASSWORD=minha_senha_postgres

# Servidor (opcional)
PORT=3000
```

⚠️ **IMPORTANTE**: O arquivo `.env` já está no `.gitignore` e não será commitado.

---

## 🚀 Iniciando a Aplicação

### Primeira Vez

```bash
# 1. Instalar dependências
bundle install

# 2. Configurar credenciais Discord
EDITOR="code --wait" rails credentials:edit
# Adicionar discord: client_id, client_secret, bot_token

# 3. Criar banco de dados
rails db:create

# 4. Executar migrations
rails db:migrate

# 5. (Opcional) Seeds
rails db:seed

# 6. Iniciar servidor
rails server
```

### Uso Diário

```bash
# Iniciar servidor
rails server

# Ou usar o bin/dev (com Tailwind watch)
bin/dev
```

Acesse: http://localhost:3000

---

## ✅ Checklist de Configuração

### Banco de Dados
- [ ] PostgreSQL instalado e rodando
- [ ] Variáveis DATABASE_* configuradas (ou usando padrões)
- [ ] `rails db:create` executado com sucesso
- [ ] `rails db:migrate` executado com sucesso

### Discord OAuth
- [ ] Aplicação criada no Discord Developer Portal
- [ ] Client ID e Client Secret obtidos
- [ ] Redirect URI configurado: `http://localhost:3000/auth/discord/callback`
- [ ] Credentials editadas: `rails credentials:edit`
- [ ] discord:client_id adicionado
- [ ] discord:client_secret adicionado

### Discord Bot (Opcional - para controle de acesso por cargo)
- [ ] Bot criado no Discord Developer Portal
- [ ] Bot Token obtido
- [ ] SERVER MEMBERS INTENT ativado
- [ ] discord:bot_token adicionado em credentials
- [ ] Bot adicionado ao servidor de testes

### Aplicação
- [ ] `bundle install` executado
- [ ] Servidor inicia sem erros: `rails server`
- [ ] Login via Discord funciona
- [ ] (Se bot configurado) Controle de acesso por cargo funciona

---

## 🔍 Verificando Configuração

### Testar Credenciais Discord

```bash
rails console

# Verificar se credentials estão configuradas
Rails.application.credentials.dig(:discord, :client_id)
# => "seu_client_id_aqui"

Rails.application.credentials.dig(:discord, :client_secret)
# => "seu_secret_aqui"

Rails.application.credentials.dig(:discord, :bot_token)
# => "seu_bot_token_aqui" (ou nil se não configurado)
```

### Testar Banco de Dados

```bash
rails console

# Verificar conexão
ActiveRecord::Base.connection.execute("SELECT 1")
# => Deve retornar resultado sem erro

# Verificar guilds
Guild.count
# => 0 (ou número de guilds no banco)
```

### Testar OAuth

1. Inicie o servidor: `rails server`
2. Acesse: http://localhost:3000
3. Clique em "Login via Discord"
4. Você deve ser redirecionado para Discord
5. Após autorizar, deve voltar para a aplicação

---

## ⚠️ Problemas Comuns

### "PG::ConnectionBad: could not connect to server"

**Causa**: PostgreSQL não está rodando ou credenciais incorretas

**Solução**:
```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql   # Linux
brew services list                  # macOS

# Iniciar PostgreSQL
sudo systemctl start postgresql     # Linux
brew services start postgresql      # macOS

# Verificar credenciais em .env ou usar padrões
```

### "Callback URL mismatch" no Discord

**Causa**: Redirect URI não configurado corretamente

**Solução**:
1. Vá em Discord Developer Portal
2. OAuth2 > General > Redirects
3. Adicione exatamente: `http://localhost:3000/auth/discord/callback`
4. Salve as mudanças

### "Your credentials aren't configured or encrypted properly"

**Causa**: Arquivo master.key ausente ou inválido

**Solução**:
```bash
# Verificar se master.key existe
ls -la config/master.key

# Se não existir, você precisa:
# 1. Obter o master.key do time (nunca commitado)
# 2. Ou recriar as credentials:
rm config/credentials.yml.enc
EDITOR=vim rails credentials:edit
# Adicione as configs Discord e salve
```

### "Usuário não tem acesso" mesmo pertencendo ao servidor

**Causa**: Bot token não configurado OU cargo obrigatório configurado na Guild

**Soluções**:
1. **Modo permissivo (recomendado para dev)**:
   - Não configure bot_token
   - Sistema libera acesso para todos

2. **Modo restrito**:
   - Configure bot_token em credentials
   - No админ, edite a Guild e remova required_discord_role_id
   - Ou adicione o cargo correto ao usuário no Discord

---

## 🔐 Segurança

### Em Desenvolvimento

- ✅ master.key no .gitignore
- ✅ .env no .gitignore
- ✅ Credentials criptografadas
- ✅ Usar localhost apenas

### Em Produção

- ⚠️ Nunca commitar master.key
- ⚠️ Nunca expor client_secret ou bot_token
- ⚠️ Usar HTTPS para redirect URIs
- ⚠️ Rotacionar tokens regularmente
- ⚠️ Limitar scopes OAuth ao mínimo necessário

---

## 📚 Referências

- [Rails Credentials Guide](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord OAuth2 Documentation](https://discord.com/developers/docs/topics/oauth2)
- [OmniAuth Discord](https://github.com/adaoraul/omniauth-discord)

---

## 💡 Dicas

### Múltiplos Ambientes

Você pode ter credentials diferentes por ambiente:

```bash
# Development (padrão)
EDITOR=vim rails credentials:edit

# Production
EDITOR=vim rails credentials:edit --environment production
```

### Backup de Credentials

```bash
# Faça backup do master.key em local seguro
cp config/master.key ~/backup/master.key.backup

# Nunca commite ou envie por chat/email
# Use gestores de senha (1Password, Bitwarden, etc)
```

### Desenvolvimento em Time

1. **Líder do projeto**: Compartilha master.key de forma segura
2. **Desenvolvedores**: Recebem master.key e colocam em config/
3. **CI/CD**: master.key como secret em GitHub Actions/GitLab CI

---

## ✨ Início Rápido

**TL;DR - Configuração Mínima para Dev**:

```bash
# 1. Banco (se não for padrão)
echo "DATABASE_PASSWORD=sua_senha" > .env

# 2. Discord Credentials
EDITOR="code --wait" rails credentials:edit
# Adicione:
# discord:
#   client_id: "..."
#   client_secret: "..."
#   # bot_token: "..."  # opcional

# 3. Setup
bundle install
rails db:create db:migrate

# 4. Run
rails server
```

Pronto! 🎉
