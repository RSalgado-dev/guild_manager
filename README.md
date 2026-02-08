# Sistema de Guildas - Discord Integration

Sistema de gerenciamento de guildas com autenticação Discord OAuth e controle de acesso baseado em servidores e cargos.

## 🚀 Início Rápido

### Requisitos

- Ruby 4.0.0
- Rails 8.1.0
- PostgreSQL 9.3+
- Node.js (para Tailwind CSS)

### Configuração Rápida

```bash
# 1. Instalar dependências
bundle install

# 2. Configurar credenciais Discord
EDITOR="code --wait" rails credentials:edit
# Adicione:
# discord:
#   client_id: "SEU_CLIENT_ID"
#   client_secret: "SEU_CLIENT_SECRET"
#   bot_token: "SEU_BOT_TOKEN"  # opcional em dev

# 3. Configurar banco de dados (se necessário)
cp .env.example .env
# Edite .env com suas credenciais PostgreSQL

# 4. Setup do banco
rails db:create db:migrate

# 5. Iniciar servidor
rails server
# ou use: bin/dev (com Tailwind watch)
```

Acesse: http://localhost:3000

---

## 📋 Variáveis de Ambiente

### Obrigatórias para Desenvolvimento

#### 1. **Banco de Dados PostgreSQL** (opcional se usar valores padrão)

```bash
DATABASE_NAME=workspace_development        # padrão
DATABASE_USERNAME=postgres                 # padrão
DATABASE_PASSWORD=postgres                 # padrão
DATABASE_HOST=localhost                    # padrão
DATABASE_PORT=5432                         # padrão
```

#### 2. **Discord OAuth** (via Rails Credentials - OBRIGATÓRIO)

```bash
# Editar credentials
EDITOR="code --wait" rails credentials:edit
```

```yaml
# Estrutura necessária em credentials.yml.enc:
discord:
  client_id: "SEU_DISCORD_CLIENT_ID"           # OBRIGATÓRIO
  client_secret: "SEU_DISCORD_CLIENT_SECRET"   # OBRIGATÓRIO
  bot_token: "SEU_DISCORD_BOT_TOKEN"           # OPCIONAL (modo permissivo sem ele)
```

**Como obter**:
1. Acesse [Discord Developer Portal](https://discord.com/developers/applications)
2. Crie uma aplicação
3. Em OAuth2: copie Client ID e Client Secret
4. Adicione redirect: `http://localhost:3000/auth/discord/callback`
5. (Opcional) Em Bot: copie o Token

📚 **Documentação completa**: [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)

### Opcionais

```bash
PORT=3000                    # Porta do servidor (padrão: 3000)
RAILS_MAX_THREADS=5          # Threads do Puma (padrão: 5)
WEB_CONCURRENCY=2            # Workers do Puma
SOLID_QUEUE_IN_PUMA=true     # Executar jobs no Puma
```

---

## 🏗️ Arquitetura

### Funcionalidades Principais

- ✅ **Autenticação Discord OAuth** - Login com um clique
- ✅ **Controle de Acesso em 2 Níveis**:
  - Nível 1: Membership em servidor Discord configurado
  - Nível 2: Cargo específico no servidor (opcional)
- ✅ **Interface Admin (ActiveAdmin)** - Gerenciamento completo
- ✅ **Sistema de Gamificação** - XP, conquistas, certificados, moeda virtual
- ✅ **Eventos e Missões** - Sistema completo de RSVP e recompensas
- ✅ **Auditoria** - Logs de todas as ações importantes

### Modelos

- **Guild** - Guildas vinculadas a servidores Discord
- **User** - Usuários autenticados via Discord
- **Role** - Cargos dentro da guilda
- **Squad** - Esquadrões com líderes e emblemas
- **Event** - Eventos com RSVP e recompensas
- **Mission** - Missões semanais
- **Achievement** - Sistema de conquistas
- **Certificate** - Certificados com requisitos para cargos
- **CurrencyTransaction** - Economia interna com rastreamento

---

## 🧪 Testes

```bash
# Executar todos os testes
rails test

# Apenas models
rails test:models

# Apenas controllers
rails test:controllers

# Teste específico
rails test test/models/user_test.rb
```

**Cobertura**:
- ✅ 208 testes de models
- ✅ 10 testes de controllers
- ✅ 362 assertions

📊 **Relatório completo**: [docs/TESTING_COVERAGE.md](docs/TESTING_COVERAGE.md)

---

## 📚 Documentação

- [CHANGELOG.md](CHANGELOG.md) - Histórico completo de mudanças
- [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md) - Configuração detalhada de ambiente
- [docs/DISCORD_INTEGRATION.md](docs/DISCORD_INTEGRATION.md) - Integração Discord OAuth
- [docs/ACTIVEADMIN_IMPLEMENTATION.md](docs/ACTIVEADMIN_IMPLEMENTATION.md) - Interface administrativa
- [docs/TESTING_COVERAGE.md](docs/TESTING_COVERAGE.md) - Cobertura de testes

---

## 🔐 Segurança

### Desenvolvimento

- ✅ Credentials criptografadas (`credentials.yml.enc`)
- ✅ `master.key` no `.gitignore`
- ✅ `.env` no `.gitignore`
- ✅ Modo permissivo sem bot_token (facilita dev)

### Produção

- ⚠️ **Nunca** commitar `master.key`
- ⚠️ **Nunca** expor tokens em logs
- ⚠️ Usar HTTPS para redirect URIs
- ⚠️ Rotacionar tokens regularmente
- ⚠️ Configurar bot_token para controle de acesso real

---

## 🛠️ Comandos Úteis

```bash
# Desenvolvimento
bin/dev                          # Servidor + Tailwind watch
rails console                    # Console Rails
rails db:reset                   # Recriar banco + seeds

# Credentials
rails credentials:edit           # Editar credentials
rails credentials:show           # Ver credentials

# Banco de Dados
rails db:migrate                 # Executar migrations
rails db:rollback                # Reverter última migration
rails db:seed                    # Executar seeds

# ActiveAdmin
rails generate active_admin:resource ModelName

# Testes
rails test                       # Todos os testes
rails test:system               # Testes de sistema

# Assets
rails assets:precompile         # Compilar assets (produção)
rails tailwindcss:build         # Compilar Tailwind
```

---

## 🚦 Status do Projeto

- **Versão**: 1.0.0
- **Rails**: 8.1.0
- **Ruby**: 4.0.0
- **Status**: ✅ Em desenvolvimento ativo

### Última Atualização: 8 de Fevereiro de 2026

- ✅ Integração Discord OAuth completa
- ✅ Controle de acesso em dois níveis
- ✅ Interface ActiveAdmin
- ✅ Sistema de testes implementado
- ✅ Documentação completa

---

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

### Padrões de Código

- Seguir Ruby Style Guide
- Escrever testes para novas funcionalidades
- Documentar mudanças no CHANGELOG.md
- Manter cobertura de testes acima de 90%

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 🆘 Suporte

### Problemas Comuns

**PostgreSQL não conecta**:
```bash
# Verificar se está rodando
sudo systemctl status postgresql   # Linux
brew services list                  # macOS
```

**Discord OAuth não funciona**:
1. Verifique credentials: `rails credentials:show`
2. Confirme redirect URI no Discord Developer Portal
3. Verifique logs: `tail -f log/development.log`

**Página restricted sempre aparece**:
- Se bot_token não configurado: funciona normalmente (modo permissivo)
- Se bot_token configurado: verifique se usuário tem cargo required_discord_role_id

### Obtendo Ajuda

- 📖 Veja a [documentação completa](docs/)
- 🐛 Abra uma [issue no GitHub](link-do-repo/issues)
- 💬 Entre em contato com o time

---

## 🎯 Roadmap

- [ ] Cache de verificações de cargo (Redis)
- [ ] Webhooks Discord para sincronização em tempo real
- [ ] Sistema de notificações
- [ ] Dashboard de métricas
- [ ] Testes de integração E2E
- [ ] Deploy automatizado
- [ ] API REST documentada
- [ ] Mobile app

---

**Desenvolvido com ❤️ usando Ruby on Rails e Discord API**

