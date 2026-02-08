# Início Rápido - Configuração de Autenticação

## 🚀 Passo a Passo para Começar

### 1. Configurar Credenciais do Discord

```bash
# Editar credenciais
EDITOR="code --wait" bin/rails credentials:edit
```

Adicione:
```yaml
discord:
  client_id: SEU_CLIENT_ID_AQUI
  client_secret: SEU_CLIENT_SECRET_AQUI
```

Para obter essas credenciais:
1. Acesse https://discord.com/developers/applications
2. Crie uma nova aplicação
3. Em OAuth2, configure a URL de redirect: `http://localhost:3000/auth/discord/callback`
4. Copie o Client ID e Client Secret

### 2. Cadastrar Servidor Discord Autorizado

**⚠️ IMPORTANTE:** Apenas usuários que pertencem a servidores configurados podem fazer login!

```bash
# Obter o ID do seu servidor Discord
# 1. Discord > Configurações > Avançado > Ative "Modo Desenvolvedor"
# 2. Clique direito no servidor > "Copiar ID do Servidor"

# Cadastrar o servidor
bin/rails discord:create_guild[ID_DO_SERVIDOR,"Nome do Servidor"]

# Verificar se foi cadastrado
bin/rails discord:list_guilds
```

### 2.1. (Opcional) Configurar Cargo Requerido

Para restringir acesso apenas a membros com cargo específico:

```bash
# Obter ID do cargo
# Discord > Configurações do Servidor > Cargos > Clique direito no cargo > Copiar ID

# Definir cargo requerido
bin/rails discord:set_required_role[GUILD_ID,ROLE_ID,"Nome do Cargo"]

# Exemplo:
bin/rails discord:set_required_role[1,987654321098765432,"Membro"]
```

**Importante**: Para verificar cargos, você precisa:
1. Configurar um `bot_token` nas credenciais (veja documentação completa)
2. Adicionar o bot ao servidor Discord

### 3. Instalar Dependências e Migrar

```bash
bundle install
bin/rails db:migrate
```

### 4. Iniciar o Servidor

```bash
bin/dev
# ou
bin/rails server
```

### 5. Testar o Login

Acesse `http://localhost:3000/auth/discord` e faça login com sua conta Discord.

**Você DEVE estar no servidor Discord que cadastrou no passo 2!**

## ❌ Problemas Comuns

### "Acesso negado. Você precisa estar em um servidor Discord autorizado"

Isso significa que:
- Você não cadastrou nenhum servidor ainda, ou
- Você não pertence ao servidor cadastrado

**Solução:**
1. Verifique os servidores cadastrados: `bin/rails discord:list_guilds`
2. Certifique-se de estar no servidor Discord correto
3. Se necessário, cadastre o servidor: `bin/rails discord:create_guild[ID,"Nome"]`

### Redirecionado para página de "Acesso Restrito"

Isso significa que:
- Você fez login com sucesso
- Mas não possui o cargo requerido pela guild

**Solução:**
1. Entre em contato com administradores do servidor Discord
2. Solicite o cargo necessário
3. Após receber o cargo, faça logout e login novamente

### "Credenciais não configuradas"

Execute: `EDITOR="code --wait" bin/rails credentials:edit` e adicione as credenciais do Discord.

## 📚 Documentação Completa

- [Configuração de Login Discord](docs/DISCORD_LOGIN.md)
- [Gerenciamento de Guilds](docs/GUILDS_DISCORD.md)
- [Controle de Acesso por Cargo](docs/ROLE_ACCESS_CONTROL.md) ⭐ Novo!

## 🔐 Níveis de Segurança

### Nível 1: Servidor Discord
- Apenas usuários de servidores autorizados podem fazer login

### Nível 2: Cargo no Servidor (Opcional)
- Configure um cargo específico requerido
- Usuários sem o cargo veem página de "Acesso Restrito"
- Podem fazer login mas não acessar recursos internos

## 🔐 Segurança

- Apenas usuários de servidores autorizados podem acessar
- Todas as ações de login/logout são registradas em logs de auditoria
- Session-based authentication
- CSRF protection ativo
