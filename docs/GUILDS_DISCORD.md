# Guilds e Integração com Discord

## Visão Geral

Todas as guilds na aplicação devem referenciar um servidor do Discord através do campo `discord_guild_id`. Isso garante que cada guilda está vinculada a um servidor Discord real.

## ⚠️ RESTRIÇÃO DE ACESSO IMPORTANTE

**Apenas usuários que pertencem a servidores Discord configurados como guilds podem fazer login na aplicação.**

Isso significa que você deve:
1. **Cadastrar os servidores Discord autorizados ANTES de permitir logins**
2. Configurar pelo menos uma guild para que usuários possam acessar o sistema
3. Gerenciar quais servidores têm acesso à aplicação

### Por que essa restrição?

Esta restrição garante que:
- Apenas membros de comunidades específicas tenham acesso
- Cada usuário esteja associado a uma guild válida
- A aplicação mantenha controle sobre quem pode acessá-la
- Guilds sejam sempre vinculadas a servidores Discord reais

## Campos da Guild

- `discord_guild_id` (obrigatório, único) - ID do servidor Discord
- `discord_name` - Nome do servidor no Discord
- `discord_icon_url` - URL do ícone do servidor Discord
- `name` - Nome da guild na aplicação
- `description` - Descrição da guild

## Criando Guilds

### Manualmente via Rake Task

```bash
# Criar uma guild manualmente
bin/rails discord:create_guild[123456789012345678,"Minha Guild"]
```

### Sincronizar do Discord (requer Bot Token)

Para sincronizar automaticamente informações do Discord, você precisa configurar um bot token:

1. Configure o bot token nas credenciais:
```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Adicione:
```yaml
discord:
  client_id: SEU_CLIENT_ID
  client_secret: SEU_CLIENT_SECRET
  bot_token: SEU_BOT_TOKEN  # Novo campo
```

2. Sincronize uma guild específica:
```bash
bin/rails discord:sync_guild[123456789012345678]
```

3. Ou sincronize todas as guilds dos usuários:
```bash
bin/rails discord:sync_all_guilds
```

### Programaticamente

```ruby
# Criar guild básica
guild = Guild.create!(
  discord_guild_id: "123456789012345678",
  name: "Minha Guild",
  description: "Descrição da guild"
)

# Criar ou encontrar guild usando método helper
guild = Guild.find_or_create_from_discord(
  "123456789012345678",
  "Nome do Discord",
  "https://cdn.discordapp.com/icons/..."
)
```

## Serviço de Sincronização

A classe `DiscordGuildService` fornece métodos para sincronizar guilds com o Discord:

```ruby
# Sincronizar uma guild específica
DiscordGuildService.sync_guild("123456789012345678")

# Sincronizar todas as guilds dos usuários
DiscordGuildService.sync_user_guilds
```

## Autenticação de Usuários

O sistema de autenticação agora:

1. Ao fazer login via Discord, verifica quais servidores Discord o usuário pertence
2. Procura por uma guild na aplicação que corresponda a um desses servidores
3. Associa o usuário à primeira guild correspondente encontrada
4. Se nenhuma guild for encontrada, cria uma guild padrão

## Tasks Rake Disponíveis

```bash
# Listar todas as guilds
bin/rails discord:list_guilds

# Criar guild manualmente
bin/rails discord:create_guild[DISCORD_GUILD_ID,"Nome"]

# Sincronizar guild específica
bin/rails discord:sync_guild[DISCORD_GUILD_ID]

# Sincronizar todas as guilds
bin/rails discord:sync_all_guilds
```

## Migração de Guilds Existentes

Se você já tem guilds no banco sem `discord_guild_id`, precisa atualizá-las:

```ruby
# No console Rails
Guild.find_each do |guild|
  guild.update!(
    discord_guild_id: "ID_DO_SERVIDOR_DISCORD",
    discord_name: guild.name
  )
end
```

Ou use um valor placeholder:
```ruby
Guild.where(discord_guild_id: nil).find_each.with_index do |guild, i|
  guild.update!(discord_guild_id: "temp_guild_#{i}")
end
```

## Validações

O modelo Guild agora valida:
- Presença de `discord_guild_id`
- Unicidade de `discord_guild_id`
- Presença de `name`
- Comprimento máximo de 100 caracteres para `name`

## Obtendo Discord Guild ID

Para obter o ID de um servidor Discord:

1. No Discord, vá em Configurações de Usuário > Avançado
2. Ative "Modo Desenvolvedor"
3. Clique com botão direito no servidor > "Copiar ID do Servidor"

## Notas de Segurança

- O `bot_token` é necessário apenas para sincronização automática de informações
- Para criar guilds manualmente, apenas o `discord_guild_id` é necessário
- Nunca exponha o bot token em logs ou código público
