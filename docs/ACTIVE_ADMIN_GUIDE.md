# Guia do ActiveAdmin - Gerenciamento de Dados

## 📊 Visão Geral

Substituímos as rake tasks por uma interface web completa usando **ActiveAdmin** para gerenciar todos os dados da aplicação.

## 🔐 Acesso ao Admin

### URL
```
http://localhost:3000/admin
```

### Autenticação

O ActiveAdmin usa o sistema de autenticação existente:
- **Login**: Faça login via Discord normalmente
- **Requisito**: Apenas usuários **admin** podem acessar o painel
- **Como tornar admin**: Configure o usuário com um cargo (Role) que tenha `is_admin: true`

## 📋 Recursos Disponíveis

### 1. **Dashboard**
- Estatísticas gerais (Guilds, Usuários, Acesso)
- Guilds e usuários recentes
- Lista de usuários sem acesso
- Cards coloridos com métricas principais

### 2. **Guilds** (`/admin/guilds`)

**Listagem**:
- Nome, ID do Discord, quantidade de usuários
- Indicador se tem acesso restrito
- Filtros por nome, Discord ID, data

**Formulário**:
- ✏️ Informações básicas (nome, descrição)
- 🎮 Dados do Discord (Guild ID, nome, ícone)
- 🔐 Controle de acesso (Cargo requerido)

**Detalhes**:
- Estatísticas completas
- Lista dos primeiros 10 usuários
- Botão "Atualizar Acesso dos Usuários"

**Ações Especiais**:
- `Atualizar Acesso dos Usuários` - Verifica e atualiza o acesso de todos os membros

### 3. **Users** (`/admin/users`)

**Scopes (Filtros Rápidos)**:
- `Todos` - Todos os usuários
- `Com Acesso` - Apenas com has_guild_access = true
- `Sem Acesso` - Apenas sem acesso
- `Admins` - Apenas administradores

**Listagem**:
- Avatar, Discord username
- Guild e Squad
- Status de acesso
- XP e moedas
- Indicador de admin

**Formulário**:
- Discord ID, username, avatar
- Guild e Squad
- XP e currency_balance
- Flag de acesso manual

**Detalhes**:
- Informações completas do usuário
- Lista de cargos (Roles)
- Últimas conquistas
- Últimas transações de moeda
- Botão "Verificar Acesso"

**Ações Especiais**:
- `Verificar Acesso` - Consulta o Discord e atualiza o acesso do usuário

### 4. **Roles** (`/admin/roles`)

**Listagem**:
- Nome, guild, cor
- Indicador de admin
- Quantidade de usuários

**Formulário**:
- Guild, nome, descrição
- Cor (formato #RRGGBB)
- Ícone
- Flag is_admin

**Detalhes**:
- Informações do cargo
- Lista dos primeiros 20 usuários com este cargo

### 5. **Squads** (`/admin/squads`)

**Listagem**:
- Nome, guild, líder
- Contador de membros (atual/máximo)

**Formulário**:
- Guild, nome, descrição
- Seleção de líder
- Máximo de membros

**Detalhes**:
- Informações do squad
- Lista completa de membros

## 🎯 Casos de Uso Comuns

### Cadastrar Nova Guild

1. Vá em `/admin/guilds`
2. Clique em "New Guild"
3. Preencha:
   - Nome da guild
   - Discord Guild ID (obrigatório)
   - Opcionalmente: Cargo requerido
4. Salve

### Configurar Cargo Requerido

1. Vá em `/admin/guilds`
2. Clique na guild desejada
3. Clique em "Edit Guild"
4. Em "Controle de Acesso":
   - Digite o Discord Role ID
   - Digite o nome do cargo
5. Salve
6. Clique em "Atualizar Acesso dos Usuários"

### Remover Cargo Requerido

1. Edite a guild
2. Limpe os campos "ID do Cargo Requerido" e "Nome do Cargo"
3. Salve

### Verificar Usuários sem Acesso

1. Vá em `/admin/users`
2. Clique no scope "Sem Acesso"
3. Ou veja no Dashboard a lista de usuários sem acesso

### Atualizar Acesso de um Usuário

**Opção 1 - Individual**:
1. Vá em `/admin/users`
2. Clique no usuário
3. Clique em "Verificar Acesso"

**Opção 2 - Em Massa**:
1. Vá em `/admin/guilds`
2. Clique na guild
3. Clique em "Atualizar Acesso dos Usuários"

### Tornar Usuário Admin

1. Crie ou edite um Role com `is_admin: true`
2. Associe o usuário a esse Role
3. O usuário poderá acessar o `/admin`

### Ajustar XP ou Moedas

1. Vá em `/admin/users`
2. Clique no usuário
3. Clique em "Edit User"
4. Ajuste `xp_points` ou `currency_balance`
5. Salve

## 🔍 Filtros e Buscas

Cada recurso tem filtros específicos:

**Guilds**:
- Nome, Discord ID, Data de criação

**Users**:
- Discord username, Discord ID
- Guild, Squad
- Tem/Não tem acesso
- XP, Currency balance
- Data de criação

**Roles**:
- Nome, Guild, É admin, Data

**Squads**:
- Nome, Guild, Data

## 📊 Dashboard

O dashboard mostra:

**Cards de Estatísticas**:
- Total de Guilds
- Total de Usuários
- Usuários com Acesso
- Total de Squads

**Tabelas**:
- 5 Guilds mais recentes
- 5 Usuários mais recentes
- Até 10 Usuários sem acesso (se houver)

## 💡 Dicas

1. **Atalhos**: Use os scopes (tabs) para filtrar rapidamente
2. **Batch Actions**: Selecione múltiplos itens para ações em lote (deletar, etc)
3. **Exportação**: ActiveAdmin suporta exportar para CSV
4. **Comentários**: Você pode adicionar comentários em qualquer recurso
5. **Auditoria**: Todas as ações são rastreáveis

## 🚀 Vantagens sobre Rake Tasks

| Rake Tasks | ActiveAdmin |
|------------|-------------|
| Terminal apenas | Interface gráfica |
| Sem visualização dos dados | Tabelas e gráficos |
| Comandos decorados | Cliques intuitivos |
| Sem filtros | Filtros e buscas |
| Difícil para não-técnicos | Fácil para qualquer um |
| Sem auditoria visual | Histórico e comentários |

## 🔒 Segurança

- Apenas usuários **admin** podem acessar
- Todas as ações passam pelos mesmos `permit_params`
- ActiveAdmin respeita os callbacks e validações do modelo
- Logs de todas as mudanças via ActiveAdmin Comments

## 📝 Customizações Futuras

Você pode adicionar mais recursos facilmente:

```ruby
# app/admin/achievements.rb
ActiveAdmin.register Achievement do
  # configuração...
end
```

Execute:
```bash
# Gerar recurso automaticamente
bin/rails generate active_admin:resource Achievement
```

## 🎨 Personalizando

### Alterar Título
Edite `config/initializers/active_admin.rb`:
```ruby
config.site_title = "Seu Título"
```

### Adicionar Novos Cards no Dashboard
Edite `app/admin/dashboard.rb`

### Customizar Estilos
Edite `app/assets/stylesheets/active_admin.scss`

## 📱 Responsividade

O ActiveAdmin é responsivo e funciona em:
- Desktop
- Tablet
- Mobile (limitado)

## 🆘 Troubleshooting

### "Você não tem permissão"
- Certifique-se que seu usuário tem um cargo com `is_admin: true`

### "Ação não encontrada"
- Verifique se o método está definido no `app/admin/[recurso].rb`

### "Erro ao salvar"
- Verifique as validações do modelo
- Veja os `permit_params` no recurso do ActiveAdmin

## 🔗 Links Úteis

- Dashboard: `/admin`
- Guilds: `/admin/guilds`
- Users: `/admin/users`
- Roles: `/admin/roles`
- Squads: `/admin/squads`
- Logout: Clique no seu nome no topo direito
