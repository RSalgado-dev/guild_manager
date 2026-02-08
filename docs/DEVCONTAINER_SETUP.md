# Setup Automático do DevContainer

## ✅ Configurações Implementadas

O script `.devcontainer/setup.sh` foi atualizado para executar automaticamente todas as configurações necessárias para rodar o Guild Manager.

### Mudanças Implementadas

#### 1. **Instalação dos Rails 8 Solid Gems**
```bash
rails solid_queue:install
rails solid_cache:install
rails solid_cable:install
```

Instala os arquivos de configuração:
- `config/queue.yml`
- `config/cache.yml`
- `config/recurring.yml`
- `db/queue_schema.rb`
- `db/cache_schema.rb`
- `db/cable_schema.rb`

#### 2. **Carregamento dos Schemas Solid**
```bash
rails runner "load Rails.root.join('db/queue_schema.rb')"
rails runner "load Rails.root.join('db/cache_schema.rb')"
rails runner "load Rails.root.join('db/cable_schema.rb')"
```

Cria as tabelas necessárias:
- **SolidQueue**: 11 tabelas para gerenciamento de jobs
- **SolidCache**: Tabela de cache
- **SolidCable**: Tabela de WebSocket messages

#### 3. **Criação Automática do Admin Temporário**
```bash
rails runner script/create_first_admin.rb
```

Cria usuário admin com:
- `discord_id: "000000000000000000"`
- `discord_username: "Admin (Temporário)"`
- `is_admin: true`
- Associado à primeira guild ou cria "Guild Administrativa"

#### 4. **Compilação do Tailwind CSS**
```bash
rails tailwindcss:build
```

Compila o Tailwind CSS automaticamente no setup inicial.

#### 5. **Mensagens de Status Melhoradas**

O script agora exibe mensagens claras sobre:
- Progresso de cada etapa
- Status de sucesso/falha
- Próximos passos após o setup
- URLs importantes para acesso

### Saída do Setup

```
✅ Setup complete!

📝 Next steps:
   1. Start the development server: bin/dev
   2. Access the app at: http://localhost:3000
   3. Login as temporary admin at: http://localhost:3000/dev/login
   4. Click 'Login como Admin Temporário'
   5. Access the admin panel at: http://localhost:3000/admin
```

## 📋 Arquivos Modificados

1. **`.devcontainer/setup.sh`**
   - Adicionadas seções para Solid gems
   - Carregamento de schemas
   - Criação de admin temporário
   - Compilação de assets
   - Mensagens informativas

2. **`README.md`**
   - Seção "Configuração Rápida" atualizada
   - Incluídos comandos dos Solid gems
   - Adicionados links para dev login e admin panel

3. **`.devcontainer/README.md`** (NOVO)
   - Documentação completa do devcontainer
   - Troubleshooting comum
   - Comandos úteis
   - Estrutura do setup

## 🎯 Benefícios

### Para Novos Desenvolvedores
- ✅ Setup completamente automatizado
- ✅ Não precisa executar comandos manualmente
- ✅ Admin temporário criado automaticamente
- ✅ Todas as dependências instaladas

### Para Manutenção
- ✅ Processo documentado e versionado
- ✅ Menos erros humanos
- ✅ Ambiente consistente entre máquinas
- ✅ Fácil de atualizar

### Para Onboarding
- ✅ Novo desenvolvedor roda o projeto em minutos
- ✅ Não precisa ler documentação extensa antes de começar
- ✅ Pode testar o sistema imediatamente
- ✅ Acesso admin disponível desde o início

## 🔄 Workflow Recomendado

### Primeira Vez (DevContainer)
1. Abrir projeto no VS Code
2. Aceitar "Reopen in Container"
3. Aguardar setup automático (~5 minutos)
4. Executar `bin/dev`
5. Acessar http://localhost:3000/dev/login
6. Clicar em "Login como Admin Temporário"
7. Navegar para http://localhost:3000/admin

### Primeira Vez (Sem DevContainer)
1. Seguir README.md seção "Configuração Rápida"
2. Executar comandos manualmente
3. Mesmo fluxo de acesso

## 🔐 Segurança

⚠️ **Admin Temporário**
- Apenas para desenvolvimento
- Deve ser deletado após criar admin real
- Não usar em produção

## 📚 Documentação Relacionada

- [README.md](/workspace/README.md) - Setup manual e arquitetura
- [.devcontainer/README.md](/workspace/.devcontainer/README.md) - Detalhes do devcontainer
- [docs/ACTIVEADMIN_ACCESS.md](/workspace/docs/ACTIVEADMIN_ACCESS.md) - Acesso ao admin
- [docs/ENVIRONMENT_SETUP.md](/workspace/docs/ENVIRONMENT_SETUP.md) - Variáveis de ambiente

## 🐛 Problemas Conhecidos

Todos os problemas comuns foram resolvidos no setup:

### ✅ Resolvido: "relation solid_queue_processes does not exist"
- **Causa**: Schemas Solid não carregados
- **Solução**: Setup carrega schemas automaticamente

### ✅ Resolvido: "Ransack needs attributes allowlisted"
- **Causa**: Ransack requer whitelist explícita
- **Solução**: Todos os modelos têm `ransackable_attributes` e `ransackable_associations`

### ✅ Resolvido: "undefined method 'delete' for Symbol"
- **Causa**: ActiveAdmin 3.4.0 mudou API do status_tag
- **Solução**: Todos os status_tag usam `class:` ao invés de símbolos

### ✅ Resolvido: Tailwind não compila
- **Causa**: Precisa compilar antes de iniciar
- **Solução**: Setup compila automaticamente e bin/dev roda watcher

### ✅ Resolvido: Sem acesso admin inicial
- **Causa**: Primeiro acesso precisa de usuário admin
- **Solução**: Admin temporário criado automaticamente

## 🎉 Conclusão

O setup do devcontainer está completo e automatizado. Desenvolvedores podem começar a trabalhar imediatamente após abrir o projeto no VS Code, sem precisar executar comandos manualmente ou lidar com erros de configuração.
