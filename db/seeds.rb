# Idempotent demo data for local development and TCC presentation.

guild = Guild.find_or_create_by!(discord_guild_id: "000000000000000001") do |record|
  record.name = "Guild Demonstracao"
  record.discord_name = "Guild Demonstracao"
  record.description = "Guilda base para demonstracao local."
end

base_role = guild.roles.find_or_create_by!(name: "Membro") do |role|
  role.description = "Cargo base de acesso"
  role.category = "base"
  role.discord_role_id = guild.required_discord_role_id.presence || "000000000000000101"
end

cosmetic_role = guild.roles.find_or_create_by!(name: "Certificado Visual") do |role|
  role.description = "Cargo cosmético concedido por certificado"
  role.category = "cosmetic"
  role.managed_by_app = false
end

admin_group = guild.permission_groups.find_or_initialize_by(name: "Administracao")
admin_group.description = "Grupo com acesso total para administradores da demo."
admin_group.all_access = true
admin_group.permissions = PermissionGroup::AVAILABLE_PERMISSIONS
admin_group.roles = [ base_role ] if admin_group.roles.empty?
admin_group.save!

Achievement.find_or_create_by!(guild: guild, code: "first_steps") do |achievement|
  achievement.name = "Primeiros Passos"
  achievement.description = "Conquista inicial da demo."
  achievement.achievement_type = "predefined"
  achievement.visibility = "catalog"
  achievement.reward_xp = 25
  achievement.reward_currency = 10
end

Certificate.find_or_create_by!(guild: guild, code: "demo_certificate") do |certificate|
  certificate.role = cosmetic_role
  certificate.name = "Certificado Demo"
  certificate.description = "Certificado base para demonstracao."
  certificate.category = "demo"
end

Ranking.find_or_create_by!(guild: guild, name: "Top XP") do |ranking|
  ranking.description = "Ranking publico por XP."
  ranking.ranking_scope = "users"
  ranking.metric = "user_xp"
  ranking.sort_direction = "desc"
  ranking.entries_limit = 10
  ranking.active = true
end
