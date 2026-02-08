# Guia de Acesso ao ActiveAdmin

Este documento explica como acessar o painel administrativo do ActiveAdmin pela primeira vez.

## 🔐 Contexto

O ActiveAdmin está configurado para:
- Usar `current_user` (do Discord OAuth) para autenticação
- Verificar `is_admin: true` no modelo User
- Bloquear acesso sem estar logado

## 🎯 Métodos de Acesso

### ⭐ Método 1: Dev Login (MAIS RÁPIDO - Development Only)

**Acesse no navegador:**
```
http://localhost:3000/dev/login
```

Ou login direto:
```
http://localhost:3000/dev/admin_login
```

Esta página permite:
- **Login automático** como admin temporário (clique em "Login como Admin Temporário")
- Login por User ID (se souber o ID de um usuário específico)
- Link para Discord OAuth (login normal)

**⚠️ Esta rota só funciona em `development` e não estará disponível em produção.**

**Se o admin temporário não existir:**
```bash
bin/rails runner script/create_first_admin.rb
```

---

### 🎯 Método 2: Discord OAuth + Promoção (Produção)

**Passo a passo:**

1. **Faça login via Discord:**
   ```
   http://localhost:3000/auth/discord
   ```

2. **No rails console, promova seu usuário:**
   ```bash
   bin/rails console
   ```
   
   ```ruby
   user = User.find_by(discord_username: 'SEU_USERNAME')
   user.update(is_admin: true)
   user.reload.is_admin # => true
   ```

3. **Acesse:**
   ```
   http://localhost:3000/admin
   ```

---

### 🛠️ Método 3: Script Helper

```bash
bin/rails runner script/create_first_admin.rb
```

Cria admin temporário:
- discord_id: `"000000000000000000"`
- Username: `"Admin (Temporário)"`
- is_admin: `true`
- Guild: `"Guild Administrativa"`

**Para usar, acesse `/dev/login` (Método 1).**

---

### 📋 Método 4: Console Rails (Manual)

```bash
bin/rails console
```

```ruby
guild = Guild.create!(
  discord_id: "999999999999999999",
  name: "Guild Admin",
  description: "Guild administrativa"
)

user = User.create!(
  discord_id: "888888888888888888",
  discord_username: "admin",
  avatar_url: "https://cdn.discordapp.com/embed/avatars/0.png",
  guild: guild,
  is_admin: true
)
```

**Para fazer login, use `/dev/login` (development).**

---

## 📋 Checklist Rápido

- [ ] Credenciais Discord configuradas (`DISCORD_CLIENT_ID` e `DISCORD_CLIENT_SECRET`)
- [ ] `rails db:migrate` executado (tabela `users` tem coluna `is_admin`)
- [ ] Admin criado: `bin/rails runner script/create_first_admin.rb`
- [ ] **Acesso `http://localhost:3000/dev/login` e clique em "Login como Admin Temporário"** ⭐
- [ ] Painel: `http://localhost:3000/admin`
  
## 🔄 Fluxo Pós-Setup

Depois do primeiro acesso:

1. **Promova seu usuário Discord real para admin** (via console ou ActiveAdmin)
2. **Remova o usuário admin temporário**:
   ```ruby
   User.find_by(discord_id: "000000000000000000")&.destroy
   ```
3. **Remova a rota /dev/login em produção** (já está protegida por `if Rails.env.development?`)

## 🚨 Troubleshooting

**Erro: "You are not authorized to perform this action"**
- Verifique se `user.is_admin` é `true`
- Confirme que está logado (verifique `session[:user_id]`)
- Use `/dev/login` para fazer login rápido em development

**Erro: "undefined method `is_admin`"**
- Execute `rails db:migrate`
- Verifique que a migration `AddIsAdminToUsers` foi aplicada

**Rota /dev/login não encontrada**
- Certifique-se de estar em ambiente `development`
- Reinicie o servidor Rails se necessário

**Redirecionado para root path**
- ActiveAdmin está bloqueando por falta de autenticação
- Use `/dev/login` para criar sessão rapidamente

## 📚 Referências

- **Controller**: `app/controllers/dev_sessions_controller.rb` (apenas development)
- **View**: `app/views/dev_sessions/new.html.erb`
- **Script**: `script/create_first_admin.rb`
- **Rotas**: `config/routes.rb` (protegidas por `if Rails.env.development?`)
- **Initializer**: `config/initializers/active_admin.rb`
- **Migration**: `db/migrate/*_add_is_admin_to_users.rb`

## 🎯 Quick Start (TL;DR)

**Mais rápido para development:**

```bash
# 1. Criar admin temporário
bin/rails runner script/create_first_admin.rb

# 2. Abrir página de dev login
# http://localhost:3000/dev/login

# 3. Clicar em "Login como Admin Temporário"

# 4. Acessar painel admin
# http://localhost:3000/admin

# 5. (Opcional) Fazer login via Discord com seu usuário real
# e promover no rails console:
rails console
User.find_by(discord_username: 'SEU_USERNAME').update(is_admin: true)
```

**Pronto!** 🎉
