namespace :discord do
  desc "Sincroniza uma guild do Discord"
  task :sync_guild, [ :discord_guild_id ] => :environment do |_t, args|
    unless args[:discord_guild_id]
      puts "Uso: rake discord:sync_guild[DISCORD_GUILD_ID]"
      exit 1
    end

    guild = DiscordGuildService.sync_guild(args[:discord_guild_id])

    if guild
      puts "Guild sincronizada com sucesso:"
      puts "  ID: #{guild.id}"
      puts "  Nome: #{guild.name}"
      puts "  Discord Guild ID: #{guild.discord_guild_id}"
    else
      puts "Falha ao sincronizar guild."
      puts "Certifique-se de que o bot_token está configurado em credentials."
    end
  end

  desc "Sincroniza todas as guilds dos usuários"
  task sync_all_guilds: :environment do
    puts "Sincronizando guilds dos usuários..."
    DiscordGuildService.sync_user_guilds
    puts "Sincronização concluída!"
  end

  desc "Lista todas as guilds cadastradas"
  task list_guilds: :environment do
    guilds = Guild.all

    if guilds.empty?
      puts "Nenhuma guild cadastrada."
    else
      puts "Guilds cadastradas:"
      guilds.each do |guild|
        puts "\n  ID: #{guild.id}"
        puts "  Nome: #{guild.name}"
        puts "  Discord Guild ID: #{guild.discord_guild_id}"
        puts "  Usuários: #{guild.users.count}"
        if guild.required_discord_role_id.present?
          puts "  ⚠️  Cargo Requerido: #{guild.required_discord_role_name} (#{guild.required_discord_role_id})"
          access_count = guild.users.where(has_guild_access: true).count
          puts "     Usuários com acesso: #{access_count} de #{guild.users.count}"
        else
          puts "  ✓ Acesso livre (sem cargo requerido)"
        end
      end
    end
  end

  desc "Cria uma guild manualmente"
  task :create_guild, [ :discord_guild_id, :name ] => :environment do |_t, args|
    unless args[:discord_guild_id] && args[:name]
      puts "Uso: rake discord:create_guild[DISCORD_GUILD_ID,\"Nome da Guild\"]"
      exit 1
    end

    guild = Guild.create(
      discord_guild_id: args[:discord_guild_id],
      name: args[:name],
      discord_name: args[:name]
    )

    if guild.persisted?
      puts "Guild criada com sucesso:"
      puts "  ID: #{guild.id}"
      puts "  Nome: #{guild.name}"
      puts "  Discord Guild ID: #{guild.discord_guild_id}"
    else
      puts "Erro ao criar guild:"
      guild.errors.full_messages.each { |msg| puts "  - #{msg}" }
    end
  end
  
  desc "Define o cargo requerido para uma guild"
  task :set_required_role, [:guild_id, :discord_role_id, :role_name] => :environment do |_t, args|
    unless args[:guild_id] && args[:discord_role_id]
      puts "Uso: rake discord:set_required_role[GUILD_ID,DISCORD_ROLE_ID,\"Nome do Cargo\"]"
      puts "\nPara obter o ID do cargo:"
      puts "1. No Discord, ative o Modo Desenvolvedor (Configurações > Avançado)"
      puts "2. Vá em Configurações do Servidor > Cargos"
      puts "3. Clique com botão direito no cargo > Copiar ID do Cargo"
      exit 1
    end
    
    guild = Guild.find(args[:guild_id])
    
    guild.update(
      required_discord_role_id: args[:discord_role_id],
      required_discord_role_name: args[:role_name] || "Membro"
    )
    
    puts "Cargo requerido configurado com sucesso!"
    puts "  Guild: #{guild.name}"
    puts "  Cargo ID: #{guild.required_discord_role_id}"
    puts "  Nome do Cargo: #{guild.required_discord_role_name}"
    puts "\nAgora apenas usuários com este cargo terão acesso aos recursos internos."
  rescue ActiveRecord::RecordNotFound
    puts "Guild não encontrada. Use 'rake discord:list_guilds' para ver as guilds disponíveis."
  end
  
  desc "Remove o cargo requerido de uma guild"
  task :remove_required_role, [:guild_id] => :environment do |_t, args|
    unless args[:guild_id]
      puts "Uso: rake discord:remove_required_role[GUILD_ID]"
      exit 1
    end
    
    guild = Guild.find(args[:guild_id])
    
    guild.update(
      required_discord_role_id: nil,
      required_discord_role_name: nil
    )
    
    puts "Cargo requerido removido com sucesso!"
    puts "  Guild: #{guild.name}"
    puts "\nTodos os membros do servidor terão acesso aos recursos internos."
  rescue ActiveRecord::RecordNotFound
    puts "Guild não encontrada."
  end
  
  desc "Atualiza o acesso de todos os usuários de uma guild"
  task :update_guild_access, [:guild_id] => :environment do |_t, args|
    unless args[:guild_id]
      puts "Uso: rake discord:update_guild_access[GUILD_ID]"
      exit 1
    end
    
    guild = Guild.find(args[:guild_id])
    users = guild.users
    
    puts "Atualizando acesso de #{users.count} usuários..."
    
    updated_count = 0
    users.find_each do |user|
      has_access = User.check_guild_role_access(guild, user.discord_id)
      if user.has_guild_access != has_access
        user.update(has_guild_access: has_access)
        updated_count += 1
      end
    end
    
    puts "Acesso atualizado para #{updated_count} usuários."
  rescue ActiveRecord::RecordNotFound
    puts "Guild não encontrada."
  end
end
