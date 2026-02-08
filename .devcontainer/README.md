# DevContainer Setup

Este devcontainer está configurado para iniciar automaticamente o ambiente de desenvolvimento do Guild Manager.

## 🔧 O Que Acontece Automaticamente

Quando você abre o projeto no DevContainer, o script `.devcontainer/setup.sh` executa automaticamente:

### 1. **Configuração do Ruby**
- Inicializa rbenv
- Verifica versão do Ruby (4.0.0)
- Atualiza RubyGems

### 2. **Instalação de Dependências**
- `bundle install` - Gems do Ruby
- `npm install` - Pacotes Node.js (se package.json existir)
- `gem install foreman` - Para gerenciar processos paralelos

### 3. **Setup do Banco de Dados**
- Aguarda PostgreSQL estar pronto
- `rails db:create` - Cria databases development e test
- `rails db:migrate` - Executa todas as migrations

### 4. **Rails 8 Solid Gems**
Instala e configura os componentes solid:
- **SolidQueue** - Background jobs
- **SolidCache** - Cache
- **SolidCable** - WebSockets

Carrega os schemas:
- `db/queue_schema.rb` - 11 tabelas para jobs
- `db/cache_schema.rb` - Tabela de cache
- `db/cable_schema.rb` - Tabela de WebSocket messages

### 5. **Admin Temporário**
Executa `script/create_first_admin.rb`:
- Cria usuário com `discord_id: "000000000000000000"`
- Username: "Admin (Temporário)"
- Flag `is_admin: true`
- Associado à primeira guild (ou cria "Guild Administrativa")

### 6. **Assets**
- Compila Tailwind CSS se disponível
- Torna executáveis os scripts em `bin/`

### 7. **Test Database**
- Prepara banco de dados de teste
- Executa seeds de teste

## 🚀 Após o Setup

O devcontainer encerra mostrando:

```
✅ Setup complete!

📝 Next steps:
   1. Start the development server: bin/dev
   2. Access the app at: http://localhost:3000
   3. Login as temporary admin at: http://localhost:3000/dev/login
   4. Click 'Login como Admin Temporário'
   5. Access the admin panel at: http://localhost:3000/admin
```

## 🔨 Comandos Úteis

### Iniciar Servidor de Desenvolvimento
```bash
bin/dev
```
Inicia Rails server + Tailwind watcher em paralelo usando foreman.

### Acessar Console Rails
```bash
rails console
```

### Executar Migrations
```bash
rails db:migrate
```

### Verificar Status do Banco
```bash
rails db:version
```

### Recriar Banco de Dados
```bash
rails db:reset
```

### Promover Usuário Discord a Admin
```bash
rails console
user = User.find_by(discord_username: 'SEU_USERNAME')
user.update(is_admin: true)
```

### Deletar Admin Temporário
```bash
rails console
User.find_by(discord_id: "000000000000000000").destroy
```

## 📋 Estrutura do DevContainer

```
.devcontainer/
├── devcontainer.json    # Configuração principal do VS Code
├── docker-compose.yml   # Serviços (app + PostgreSQL)
├── Dockerfile          # Imagem do container
├── setup.sh            # Script executado no postCreateCommand
└── README.md           # Esta documentação
```

## 🐛 Troubleshooting

### Erro: "relation solid_queue_processes does not exist"
Execute:
```bash
rails solid_queue:install
rails runner "load Rails.root.join('db/queue_schema.rb')"
```

### Erro: "Ransack needs attributes allowlisted"
Os modelos já possuem `ransackable_attributes` e `ransackable_associations` definidos:
- `app/models/user.rb`
- `app/models/guild.rb`
- `app/models/role.rb`
- `app/models/squad.rb`

### Erro: "undefined method 'delete' for Symbol"
ActiveAdmin 3.4.0 usa `class:` ao invés de símbolos:
```ruby
# ✅ Correto
status_tag("Sim", class: "ok")

# ❌ Errado
status_tag("Sim", :ok)
```

### Tailwind não compila
```bash
# Compilar manualmente
rails tailwindcss:build

# Ou iniciar watcher
rails tailwindcss:watch
```

### Admin temporário não funciona
Verifique se o usuário existe:
```bash
rails console
User.find_by(discord_id: "000000000000000000")
```

Se não existir, recrie:
```bash
rails runner script/create_first_admin.rb
```

## 🔐 Segurança

⚠️ **IMPORTANTE**: O usuário admin temporário é apenas para setup inicial em desenvolvimento.

**Após o primeiro login via Discord:**
1. Promova seu usuário real a admin
2. Delete o usuário temporário
3. Use apenas Discord OAuth em produção

## 📚 Documentação Adicional

- [ENVIRONMENT_SETUP.md](/workspace/docs/ENVIRONMENT_SETUP.md) - Variáveis de ambiente
- [ACTIVEADMIN_ACCESS.md](/workspace/docs/ACTIVEADMIN_ACCESS.md) - Acesso ao painel admin
- [TESTING_COVERAGE.md](/workspace/docs/TESTING_COVERAGE.md) - Testes e cobertura
- [README.md](/workspace/README.md) - Documentação principal

## 🔄 Rebuild do Container

Se precisar reconstruir completamente o container:

1. No VS Code: `Ctrl/Cmd + Shift + P`
2. Digite: "Dev Containers: Rebuild Container"
3. Aguarde o setup automático

Ou via CLI:
```bash
devcontainer up --remove-existing-container
```
