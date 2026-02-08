# Sistema de Controle de Acesso - Visão Geral

## 🔐 Arquitetura de Segurança

```
┌─────────────────────────────────────────────────────────────┐
│                    USUÁRIO TENTA LOGIN                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │ Pertence a servidor   │
            │  configurado?         │
            └───────────┬───────────┘
                       │
            ┌──────────┴──────────┐
            │ NÃO                 │ SIM
            ▼                     ▼
    ┌───────────────┐     ┌──────────────────┐
    │ ❌ LOGIN      │     │ Guild tem cargo  │
    │   NEGADO      │     │  requerido?      │
    └───────────────┘     └────────┬─────────┘
                                   │
                        ┌──────────┴──────────┐
                        │ NÃO                 │ SIM
                        ▼                     ▼
                ┌───────────────┐     ┌──────────────────┐
                │ ✅ ACESSO     │     │ Usuário tem o    │
                │    TOTAL      │     │ cargo?           │
                └───────────────┘     └────────┬─────────┘
                                               │
                                    ┌──────────┴──────────┐
                                    │ NÃO                 │ SIM
                                    ▼                     ▼
                            ┌────────────────┐    ┌───────────────┐
                            │ ⚠️  ACESSO     │    │ ✅ ACESSO     │
                            │   RESTRITO     │    │    TOTAL      │
                            └────────────────┘    └───────────────┘
```

## 📋 Resumo da Implementação

### Banco de Dados

**Tabela `guilds`**:
- ✅ `required_discord_role_id` - ID do cargo requerido (opcional)
- ✅ `required_discord_role_name` - Nome do cargo para exibição

**Tabela `users`**:
- ✅ `has_guild_access` - Flag booleana indicando se tem acesso

### Modelos

**User**:
- ✅ `find_or_create_from_discord` - Verifica cargo ao criar/atualizar
- ✅ `check_guild_role_access` - Consulta API do Discord para verificar cargo

**Guild**:
- ✅ Campos para cargo requerido

### Controllers

**SessionsController**:
- ✅ Redireciona para `/restricted` se sem acesso
- ✅ Registra status de acesso em audit log

**ApplicationController**:
- ✅ `has_guild_access?` - Helper para verificar acesso
- ✅ `require_guild_access` - Before action para proteger rotas

**AccessController**:
- ✅ Página de acesso restrito

### Views

- ✅ `/restricted` - Página explicativa para usuários sem cargo
- ✅ Instruções de como obter acesso
- ✅ Link direto para servidor Discord

### Rotas

```ruby
GET  /restricted              # Página de acesso restrito
```

### Rake Tasks

```bash
# Configurar cargo requerido
bin/rails discord:set_required_role[GUILD_ID,ROLE_ID,"Nome"]

# Remover cargo requerido
bin/rails discord:remove_required_role[GUILD_ID]

# Atualizar acesso dos usuários
bin/rails discord:update_guild_access[GUILD_ID]

# Listar guilds (mostra status)
bin/rails discord:list_guilds
```

## 🎯 Casos de Uso

### Caso 1: Guild sem cargo configurado
```ruby
# Todos do servidor têm acesso
user.has_guild_access? # => true
```

### Caso 2: Guild com cargo "Membro"
```ruby
# Apenas usuários com cargo "Membro" têm acesso
user.has_guild_access? # => true/false (depende do cargo)
```

### Caso 3: Proteger rota específica
```ruby
class AdminController < ApplicationController
  before_action :require_guild_access  # Requer cargo
  before_action :require_admin         # E ser admin
end
```

## 📊 Estatísticas

Execute para ver status de acesso:
```bash
bin/rails discord:list_guilds
```

Saída exemplo:
```
Guilds cadastradas:

  ID: 1
  Nome: Minha Comunidade
  Discord Guild ID: 123456789012345678
  Usuários: 10
  ⚠️  Cargo Requerido: Membro (987654321098765432)
     Usuários com acesso: 7 de 10
```

## 🔧 Configuração Necessária

### Obrigatório
- ✅ Discord OAuth configurado (client_id, client_secret)
- ✅ Guild cadastrada
- ✅ Usuários no servidor Discord

### Para Verificação de Cargo
- ⚙️ Bot Token configurado
- ⚙️ Bot adicionado ao servidor
- ⚙️ Bot com permissão "View Server Members"

## 📝 Fluxo de Trabalho Recomendado

1. **Setup Inicial**:
   ```bash
   # Criar guild
   bin/rails discord:create_guild[ID,"Nome"]
   ```

2. **Modo Aberto** (sem cargo):
   - Todos do servidor têm acesso
   - Ideal para começar

3. **Modo Restrito** (com cargo):
   ```bash
   # Definir cargo
   bin/rails discord:set_required_role[1,ROLE_ID,"Membro"]
   ```
   - Apenas membros com cargo específico têm acesso
   - Outros veem página de acesso restrito

4. **Manutenção**:
   ```bash
   # Atualizar acesso periódicamente
   bin/rails discord:update_guild_access[1]
   ```

## 🚀 Vantagens

- ✅ **Duas camadas** de segurança
- ✅ **Flexível**: Cargo opcional por guild
- ✅ **User-friendly**: Página explicativa para quem não tem acesso
- ✅ **Auditável**: Logs de todas as ações
- ✅ **Seguro**: Verificação via API oficial do Discord
- ✅ **Fail-safe**: Modo permissivo em caso de erro
