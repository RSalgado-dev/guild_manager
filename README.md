# Guild Manager

Aplicação Rails para gestão de guildas com login Discord, controle de acesso por guilda/cargo, módulos de membros, gestão operacional e auditoria.

## Escopo

O sistema centraliza:

- autenticação via Discord OAuth;
- autorização por guilda, cargo base e grupos de permissão;
- painel de membros com perfil, personagens, squads, eventos, missões, conquistas, certificados, rankings e loja;
- painel operacional em `/manage` com permissões delegadas;
- ActiveAdmin em `/admin` como fallback técnico restrito a cargo máximo;
- sincronização de cargos Discord por jobs e webhook interno;
- trilha de auditoria para ações relevantes.

## Documentação Mantida

- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): setup local, credenciais e comandos de desenvolvimento.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): mapa dos principais módulos do código.
- [docs/OPERATIONS.md](docs/OPERATIONS.md): rotinas operacionais, permissões, jobs e saúde.
- [docs/TESTING.md](docs/TESTING.md): comandos e regras de teste.

## Execução no DevContainer

Rode comandos Rails dentro do container `guild_manager_devcontainer-app-1`, nunca no host.

```bash
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && <command>'
```

Exemplos:

```bash
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && bin/rails test'
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && bin/rubocop'
```

## Setup Local

1. Configure variáveis locais se os padrões do banco não servirem:

```bash
cp .env.example .env
```

2. Configure as credenciais Discord nas Rails credentials:

```bash
EDITOR="vim" bin/rails credentials:edit
```

Estrutura esperada:

```yaml
discord:
  client_id: "..."
  client_secret: "..."
  bot_token: "..."
```

`bot_token` é opcional em desenvolvimento, mas necessário para sincronização real de cargos.

3. Prepare o app:

```bash
bin/setup --skip-server
bin/rails runner script/create_first_admin.rb
```

4. Suba o servidor:

```bash
bin/dev
```

URLs principais:

- App: `http://localhost:3000`
- Login de desenvolvimento: `http://localhost:3000/dev/login`
- Gestão operacional: `http://localhost:3000/manage`
- ActiveAdmin técnico: `http://localhost:3000/admin`
- Health check completo: `http://localhost:3000/up/full`

## Comandos Úteis

```bash
bin/rails db:prepare
bin/rails db:migrate
bin/rails console
bin/rails test
bin/rails test:system
bin/rubocop
bin/ci
```

Tasks específicas:

```bash
bin/rails discord:list_guilds
bin/rails discord:create_guild[DISCORD_GUILD_ID,"Nome da Guilda"]
bin/rails discord:set_required_role[GUILD_ID,DISCORD_ROLE_ID,"Nome do Cargo"]
bin/rails discord:update_guild_access[GUILD_ID]
bin/rails demo:seed_presentation_guild
```

## Stack

- Ruby 4.0.0
- Rails 8.1
- PostgreSQL
- Hotwire, Importmap e Tailwind
- ActiveAdmin e Devise
- OmniAuth Discord, Discord API e Faraday
- Solid Queue, Solid Cache e Solid Cable
- Minitest, Capybara/Selenium, WebMock e Mocha

## Segurança

- Segredos Discord ficam em `config/credentials.yml.enc`.
- `config/master.key`, `.env`, logs e uploads locais não devem ser commitados.
- Tokens Discord persistidos em usuários usam Active Record Encryption.
- Em produção, configure as chaves `ACTIVE_RECORD_ENCRYPTION_*` ou `credentials.active_record_encryption`.
- `DISCORD_WEBHOOK_SECRET` protege o webhook interno de atualização de membros.
