# Controle de Acesso por Cargo do Discord

## Visão Geral

A aplicação possui **dois níveis de controle de acesso**:

1. **Nível 1 - Servidor Discord**: O usuário deve pertencer a um servidor Discord configurado
2. **Nível 2 - Cargo no Servidor**: O usuário deve ter um cargo específico naquele servidor

## Como Funciona

### Fluxo de Autenticação

```
Usuário faz login
    ↓
Pertence a servidor configurado?
    ↓ Não → Acesso Negado
    ↓ Sim
Tem o cargo requerido?
    ↓ Não → Página de Acesso Restrito
    ↓ Sim
Acesso aos Recursos Internos
```

## Configuração

### 1. Obter o ID do Cargo no Discord

1. No Discord, ative o **Modo Desenvolvedor**:
   - Configurações de Usuário > Avançado > Modo Desenvolvedor ✓

2. Vá em **Configurações do Servidor** > **Cargos**

3. Clique com o **botão direito** no cargo desejado

4. Clique em **"Copiar ID do Cargo"**

### 2. Configurar Cargo Requerido

```bash
# Definir cargo requerido para uma guild
bin/rails discord:set_required_role[GUILD_ID,ROLE_ID,"Nome do Cargo"]

# Exemplo:
bin/rails discord:set_required_role[1,987654321098765432,"Membro"]
```

### 3. Configurar Bot Token (Necessário)

Para verificar os cargos dos usuários, você precisa de um **Bot Token**:

1. Acesse https://discord.com/developers/applications
2. Selecione sua aplicação
3. Vá em **Bot**
4. Copie o **Token**
5. Configure nas credenciais:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Adicione:
```yaml
discord:
  client_id: SEU_CLIENT_ID
  client_secret: SEU_CLIENT_SECRET
  bot_token: SEU_BOT_TOKEN  # Adicione esta linha
```

6. **Adicione o bot ao servidor**:
   - Na seção OAuth2 > URL Generator
   - Selecione scopes: `bot`
   - Selecione permissões: `Read Messages/View Channels`
   - Use a URL gerada para adicionar o bot ao servidor

## Comandos Rake

### Gerenciar Cargos Requeridos

```bash
# Definir cargo requerido
bin/rails discord:set_required_role[GUILD_ID,ROLE_ID,"Nome"]

# Remover cargo requerido (libera acesso para todos)
bin/rails discord:remove_required_role[GUILD_ID]

# Atualizar acesso de todos os usuários de uma guild
bin/rails discord:update_guild_access[GUILD_ID]

# Listar guilds (mostra status dos cargos)
bin/rails discord:list_guilds
```

## Usando no Código

### Proteger Rotas no Controller

```ruby
class MeuController < ApplicationController
  # Requer apenas login
  before_action :require_login
  
  # OU
  
  # Requer login E cargo da guild
  before_action :require_guild_access
end
```

### Verificar Acesso nas Views

```erb
<% if has_guild_access? %>
  <!-- Conteúdo para membros com acesso -->
  <p>Bem-vindo aos recursos internos!</p>
<% else %>
  <!-- Conteúdo para quem não tem acesso -->
  <p>Você precisa do cargo de Membro para acessar.</p>
<% end %>
```

### Helpers Disponíveis

- `has_guild_access?` - Retorna true se o usuário tem acesso aos recursos internos
- `require_guild_access` - Redireciona para página restrita se não tiver acesso
- `current_user.has_guild_access` - Atributo booleano do usuário

## Página de Acesso Restrito

Usuários sem o cargo necessário são redirecionados para `/restricted`, onde podem:

- Ver qual cargo é necessário
- Ver instruções de como obter acesso
- Acessar o servidor Discord diretamente
- Fazer logout

## Comportamento

### Quando Cargo Está Configurado

- ✅ Usuário com cargo → Acesso total
- ⚠️ Usuário sem cargo → Acesso restrito (página `/restricted`)
- ❌ Não está no servidor → Login negado

### Quando Cargo NÃO Está Configurado

- ✅ Qualquer usuário do servidor → Acesso total

## Modo Permissivo

Se o bot token não estiver configurado ou houver erro na verificação:
- O sistema opera em **modo permissivo**
- Todos os usuários do servidor configurado têm acesso
- Um warning é registrado nos logs

## Atualização de Acesso

O acesso é verificado:
- ✅ **Em cada login** - Automaticamente
- ✅ **Manualmente via rake** - Para atualizar usuários existentes

```bash
# Forçar atualização de acesso para todos os usuários de uma guild
bin/rails discord:update_guild_access[GUILD_ID]
```

## Exemplo Completo

```bash
# 1. Criar guild
bin/rails discord:create_guild[123456789012345678,"Minha Comunidade"]

# 2. Definir cargo requerido
bin/rails discord:set_required_role[1,987654321098765432,"Membro Verificado"]

# 3. Listar para confirmar
bin/rails discord:list_guilds

# Saída:
# Guilds cadastradas:
#   ID: 1
#   Nome: Minha Comunidade
#   Discord Guild ID: 123456789012345678
#   Usuários: 5
#   ⚠️  Cargo Requerido: Membro Verificado (987654321098765432)
#      Usuários com acesso: 3 de 5
```

## Troubleshooting

### "Modo permissivo" nos logs

**Causa**: Bot token não configurado ou bot não está no servidor

**Solução**:
1. Configure o bot token nas credenciais
2. Adicione o bot ao servidor Discord
3. Verifique as permissões do bot

### Usuário não ganha acesso após receber cargo

**Solução**: Faça logout e login novamente, ou execute:
```bash
bin/rails discord:update_guild_access[GUILD_ID]
```

### Bot retorna erro 403

**Causa**: Bot não tem permissão para ver membros do servidor

**Solução**: Adicione a permissão "View Server Members" ao bot

## Segurança

- Verificação de cargos via API oficial do Discord
- Logs de auditoria registram status de acesso
- Modo permissivo em caso de erro (evita bloqueio total)
- Token do bot armazenado de forma segura nas credenciais
