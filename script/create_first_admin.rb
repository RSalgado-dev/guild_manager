#!/usr/bin/env ruby
# frozen_string_literal: true

# Script para criar o primeiro usuário administrador
# Uso: bin/rails runner script/create_first_admin.rb

puts "🔧 Criando primeiro usuário administrador..."
puts ""

# Encontra ou cria um usuário admin de teste
user = User.find_or_create_by(discord_id: "000000000000000000") do |u|
  u.discord_username = "Admin (Temporário)"
  u.xp_points = 0
  u.currency_balance = 0

  # Precisa de uma guild - cria uma temporária se necessário
  guild = Guild.first || Guild.create!(
    name: "Guild Administrativa",
    discord_guild_id: "000000000000000001"
  )

  u.guild = guild
  u.is_admin = true
end

# Garante que is_admin está true
user.update(is_admin: true) unless user.is_admin?

puts "✅ Usuário administrador criado/atualizado:"
puts ""
puts "   Discord ID: #{user.discord_id}"
puts "   Username: #{user.discord_username}"
puts "   Is Admin: #{user.is_admin}"
puts "   Guild: #{user.guild.name}"
puts ""
puts "⚠️  IMPORTANTE: Este é um usuário temporário para acesso inicial."
puts "   Depois de fazer login via Discord, você pode:"
puts "   1. Promover seu usuário Discord a admin no console"
puts "   2. Deletar este usuário temporário"
puts ""
puts "📋 Para promover seu usuário Discord a admin:"
puts "   rails console"
puts "   user = User.find_by(discord_username: 'SEU_USERNAME')"
puts "   user.update(is_admin: true)"
puts ""
puts "🔐 Para fazer login sem Discord (apenas este usuário):"
puts "   1. Abra o rails console: rails console"
puts "   2. Execute: session = ActionDispatch::Integration::Session.new(Rails.application)"
puts "   3. Ou modifique temporariamente o SessionsController"
puts ""
puts "🌐 Acesse o painel admin em: http://localhost:3000/admin"
puts ""
