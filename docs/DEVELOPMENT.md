# Desenvolvimento

Este projeto deve ser executado dentro do DevContainer `guild_manager_devcontainer-app-1`. Use sempre binstubs Rails.

## Wrapper de Comando

```bash
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && <command>'
```

Substitua `<command>` por `bin/rails test`, `bin/rubocop`, `bin/rails db:migrate`, `bin/dev` ou outro comando do projeto.

## Primeira Configuração

Copie `.env.example` se precisar alterar os padrões de banco:

```bash
cp .env.example .env
```

As credenciais Discord ficam em Rails credentials:

```bash
EDITOR="vim" bin/rails credentials:edit
```

Formato:

```yaml
discord:
  client_id: "..."
  client_secret: "..."
  bot_token: "..."
```

No Discord Developer Portal, configure o redirect local:

```text
http://localhost:3000/auth/discord/callback
```

Prepare dependências e banco:

```bash
bin/setup --skip-server
```

Crie o admin temporário de desenvolvimento:

```bash
bin/rails runner script/create_first_admin.rb
```

## Rodando o App

```bash
bin/dev
```

`bin/dev` inicia Rails e o watcher do Tailwind via `Procfile.dev`.

Rotas úteis em desenvolvimento:

- `http://localhost:3000`: app.
- `http://localhost:3000/dev/login`: login local com usuário temporário.
- `http://localhost:3000/manage`: gestão operacional.
- `http://localhost:3000/admin`: ActiveAdmin técnico.
- `http://localhost:3000/up/full`: health check completo.

## Banco e Assets

```bash
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:seed
bin/rails tailwindcss:build
```

Use `bin/setup --skip-server --reset` quando precisar recriar o banco local.

## Jobs

Em produção, os jobs recorrentes ficam em `config/recurring.yml` e rodam via Solid Queue. Para testar manualmente:

```bash
bin/rails runner 'DiscordGuildRolesSyncJob.perform_now'
bin/rails runner 'DiscordMembersSyncJob.perform_now'
bin/rails runner 'DiscordManagedRoleReconciliationJob.perform_now'
```

## Problemas Comuns

Se o login Discord falhar, confira as credentials, o redirect URI e se o usuário pertence a uma guilda cadastrada.

Se o acesso interno cair em `/restricted`, confira `Guild#required_discord_role_id`, roles sincronizadas e `User#has_guild_access`.

Se assets não atualizarem, rode `bin/rails tailwindcss:build` ou reinicie `bin/dev`.
