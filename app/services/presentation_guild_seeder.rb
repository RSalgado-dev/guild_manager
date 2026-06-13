# frozen_string_literal: true

class PresentationGuildSeeder
  GUILD_DISCORD_ID = "900000000000000001"
  DEV_ADMIN_DISCORD_ID = "000000000000000000"
  DEFAULT_USER_COUNT = 100
  RANDOM_SEED = 20_260_505

  def self.call(user_count: DEFAULT_USER_COUNT, reset: true, reference_time: Time.zone.now)
    new(user_count:, reset:, reference_time:).call
  end

  def initialize(user_count:, reset:, reference_time:)
    @user_count = [ user_count.to_i, 1 ].max
    @reset = reset
    @reference_time = reference_time
    @start_time = reference_time - 30.days
    @random = Random.new(RANDOM_SEED)
    @roles = {}
    @permission_groups = {}
    @users = []
    @squads = []
    @achievements = {}
    @certificates = {}
    @missions = {}
    @store_items = []
    @submission_sequences = Hash.new(0)
  end

  def call
    ensure_allowed_environment!
    ensure_reset_policy!
    purge_existing_guild! if @reset

    create_guild!
    create_roles!
    create_permission_groups!
    create_users!
    create_squads!
    create_squad_invitations!
    create_game_characters!
    create_achievements!
    create_certificates!
    create_missions!
    create_automatic_activity!
    create_events!
    create_manual_mission_submissions!
    create_mission_requests!
    create_certificate_grants!
    create_store!
    create_rankings!
    create_audit_trail!

    summary
  end

  private

  attr_reader :guild, :admin, :random, :reference_time, :start_time

  def ensure_allowed_environment!
    return if Rails.env.development? || Rails.env.test?

    raise "PresentationGuildSeeder deve rodar apenas em development ou test"
  end

  def ensure_reset_policy!
    return if @reset
    return unless Guild.exists?(discord_guild_id: GUILD_DISCORD_ID)

    raise "Guilda mock ja existe. Rode com RESET=true para recriar os dados de apresentacao."
  end

  def purge_existing_guild!
    existing_guild = Guild.find_by(discord_guild_id: GUILD_DISCORD_ID)
    return unless existing_guild

    StoreOrder.joins(:store_item).where(store_items: { guild_id: existing_guild.id }).delete_all
    existing_guild.destroy!
  end

  def create_guild!
    @guild = Guild.create!(
      name: "Aurora do Abismo",
      discord_name: "Aurora do Abismo",
      discord_guild_id: GUILD_DISCORD_ID,
      discord_icon_url: "https://cdn.discordapp.com/icons/#{GUILD_DISCORD_ID}/presentation.png",
      description: "Guilda mock para apresentacao: 30 dias de atividade, membros, squads, eventos, missoes, loja e auditoria.",
      character_template: [
        { "key" => "nickname", "label" => "Nickname", "field_type" => "string", "required" => true },
        { "key" => "level", "label" => "Nivel", "field_type" => "integer", "required" => true },
        { "key" => "power", "label" => "Poder", "field_type" => "integer", "required" => true },
        { "key" => "class", "label" => "Classe", "field_type" => "string", "required" => true },
        { "key" => "build", "label" => "Build", "field_type" => "string", "required" => true },
        { "key" => "gear_score", "label" => "Gear Score", "field_type" => "integer", "required" => true },
        { "key" => "healer", "label" => "Suporte", "field_type" => "boolean", "required" => false }
      ]
    )
    stamp!(guild, start_time)
  end

  def create_roles!
    role_specs = [
      [ :base, "Membro da Aurora", "Cargo base para acessar a plataforma.", "base", false, "900000000000000101" ],
      [ :novice, "Recruta", "Membro em periodo de integracao.", "base", false, "900000000000000102" ],
      [ :event_officer, "Oficial de Eventos", "Organiza e revisa eventos da guilda.", "administrative", false, "900000000000000201" ],
      [ :mission_curator, "Curador de Missoes", "Revisa missoes e pedidos especiais.", "administrative", false, "900000000000000202" ],
      [ :store_keeper, "Tesoureiro", "Opera loja, moedas e entregas.", "administrative", false, "900000000000000203" ],
      [ :auditor, "Auditor", "Acompanha logs e rastreabilidade.", "administrative", false, "900000000000000204" ],
      [ :guild_master, "Guild Master", "Cargo maximo da apresentacao.", "role_maximum", true, "900000000000000205" ],
      [ :artisan, "Artesao", "Cargo especial para pedidos de crafting.", "special", false, "900000000000000301" ],
      [ :relic_hunter, "Cacador de Reliquias", "Cargo especial para exploracao.", "special", false, "900000000000000302" ],
      [ :mentor, "Instrutor", "Cargo especial para mentoria.", "special", false, "900000000000000303" ],
      [ :raid_leader, "Lider de Raid", "Cargo especial para conduzir raids.", "special", false, "900000000000000304" ],
      [ :cert_raid, "Certificado Lideranca", "Cargo cosmetico de certificado.", "cosmetic", false, nil ],
      [ :cert_crafter, "Certificado Artesao", "Cargo cosmetico de certificado.", "cosmetic", false, nil ],
      [ :cert_pvp, "Certificado Arena", "Cargo cosmetico de certificado.", "cosmetic", false, nil ],
      [ :cert_lore, "Certificado Cronista", "Cargo cosmetico de certificado.", "cosmetic", false, nil ],
      [ :cosmetic_elite, "Nome Dourado", "Cosmetico de prestigio.", "cosmetic", false, nil ],
      [ :cosmetic_founder, "Fundador Mock", "Cosmetico historico da guilda.", "cosmetic", false, nil ]
    ]

    role_specs.each_with_index do |(key, name, description, category, is_admin, discord_role_id), index|
      @roles[key] = guild.roles.create!(
        name: name,
        description: description,
        category: category,
        is_admin: is_admin,
        managed_by_app: false,
        discord_role_id: discord_role_id
      )
      stamp!(@roles[key], start_time + index.hours)
    end

    guild.update!(
      required_discord_role_id: @roles[:base].discord_role_id,
      required_discord_role_name: @roles[:base].name
    )
  end

  def create_permission_groups!
    @permission_groups[:maximum] = create_permission_group!(
      name: "Conselho Maximo",
      description: "Acesso total para demonstracao da banca.",
      permissions: PermissionGroup::AVAILABLE_PERMISSIONS,
      roles: [ @roles[:guild_master] ],
      all_access: true
    )
    @permission_groups[:events] = create_permission_group!(
      name: "Operacao de Eventos",
      description: "Cria eventos, revisa presenca e distribui recompensas.",
      permissions: %w[manage_events manage_members],
      roles: [ @roles[:event_officer], @roles[:raid_leader] ]
    )
    @permission_groups[:missions] = create_permission_group!(
      name: "Curadoria de Missoes",
      description: "Revisa submissões e pedidos de missao.",
      permissions: %w[manage_missions review_mission_submissions manage_achievements grant_achievements],
      roles: [ @roles[:mission_curator], @roles[:mentor] ]
    )
    @permission_groups[:store] = create_permission_group!(
      name: "Loja e Recompensas",
      description: "Gerencia catalogo, pedidos e certificados.",
      permissions: %w[manage_store fulfill_store_orders manage_certificates grant_certificates],
      roles: [ @roles[:store_keeper], @roles[:artisan] ]
    )
    @permission_groups[:audit] = create_permission_group!(
      name: "Auditoria",
      description: "Acesso de leitura aos logs operacionais.",
      permissions: %w[view_audit_logs manage_rankings],
      roles: [ @roles[:auditor] ]
    )
  end

  def create_permission_group!(name:, description:, permissions:, roles:, all_access: false)
    group = guild.permission_groups.build(
      name: name,
      description: description,
      permissions: permissions,
      all_access: all_access
    )
    roles.each { |role| group.permission_group_roles.build(role: role) }
    group.save!
    stamp!(group, start_time + 1.day)
    group
  end

  def create_users!
    first_names = %w[
      Aline Bruno Caio Diana Elias Fernanda Gustavo Helena Igor Julia Kaue Laura
      Marcos Nina Otavio Paula Renan Sara Tiago Ursula Victor Yasmin Zeca Bianca
      Daniel Erica Fabio Gaia Hugo Iris Jonas Karen Luan Marina Noel Olivia Pedro
      Queila Ravi Sofia Tales Vitoria Wesley Xenia Yuri Zara
    ]
    aliases = %w[
      Nova Prisma Eclipse Atlas Lynx Orion Vega Nix Onyx Flux Hydra Lotus Pixel
      Rune Echo Blaze Ember Frost Arc Vortex Zenith Terra Byte Quartz Pulse
    ]

    @user_count.times do |index|
      joined_at = start_time + random.rand(0..12).days + random.rand(0..23).hours
      discord_id = index.zero? ? DEV_ADMIN_DISCORD_ID : format("9000000000001%05d", index)
      first_name = first_names[index % first_names.size]
      handle = aliases[(index * 7) % aliases.size]

      user = User.find_or_initialize_by(discord_id: discord_id)
      user.user_roles.destroy_all if user.persisted?
      user.assign_attributes(
        guild: guild,
        squad: nil,
        discord_username: index.zero? ? "admin_demo" : "#{first_name.downcase}_#{handle.downcase}_#{index.to_s.rjust(3, '0')}",
        discord_nickname: index.zero? ? "Admin Demo" : "#{first_name} #{handle}",
        discord_avatar_url: "https://cdn.discordapp.com/avatars/#{discord_id}/mock.png",
        email: index.zero? ? "admin.demo@example.test" : "membro#{index.to_s.rjust(3, '0')}@example.test",
        discord_access_token: "mock-access-token-#{index}",
        discord_refresh_token: "mock-refresh-token-#{index}",
        discord_token_expires_at: reference_time + 14.days,
        discord_roles_synced_at: joined_at + random.rand(1..8).days,
        has_guild_access: index < (@user_count * 0.94).ceil,
        is_admin: index.zero?,
        xp_points: index.zero? ? 6_000 : 150 + (index * 29) + random.rand(0..900),
        currency_balance: index.zero? ? 6_000 : 850 + random.rand(0..1_200)
      )
      user.save!
      stamp!(user, joined_at)

      assign_role!(user, @roles[:base], primary: true)
      assign_extra_roles!(user, index)
      @users << user
      @admin = user if index.zero?
    end
  end

  def assign_extra_roles!(user, index)
    return assign_admin_roles!(user) if index.zero?

    assign_role!(user, @roles[:novice]) if index % 11 == 0
    assign_role!(user, @roles[:event_officer]) if index % 17 == 0
    assign_role!(user, @roles[:mission_curator]) if index % 19 == 0
    assign_role!(user, @roles[:store_keeper]) if index % 23 == 0
    assign_role!(user, @roles[:auditor]) if index % 29 == 0
    assign_role!(user, @roles[:artisan]) if index % 5 == 0
    assign_role!(user, @roles[:relic_hunter]) if index % 7 == 0
    assign_role!(user, @roles[:mentor]) if index % 9 == 0
    assign_role!(user, @roles[:raid_leader]) if index % 13 == 0
    assign_role!(user, @roles[:cosmetic_founder]) if index <= 8
  end

  def assign_admin_roles!(user)
    [ :guild_master, :event_officer, :mission_curator, :store_keeper, :auditor, :cosmetic_founder ].each do |role_key|
      assign_role!(user, @roles[role_key])
    end
  end

  def assign_role!(user, role, primary: false)
    user.user_roles.create!(role: role, primary: primary)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    user.user_roles.find_by!(role: role)
  end

  def create_squads!
    squad_specs = [
      [ "Vanguarda Solar", "SOLAR", "Progressao principal de raids e objetivos semanais." ],
      [ "Sentinelas do Norte", "NORTE", "Defesa, suporte e protecao de rotas." ],
      [ "Lobos de Jade", "JADE", "Equipe de exploracao e coleta rara." ],
      [ "Ordem Prisma", "PRISMA", "Grupo de mentoria e onboarding." ],
      [ "Eclipse Tatico", "ECLIPSE", "Squad focado em arena e PvP." ],
      [ "Forja Arcana", "FORJA", "Artesaos, economia e crafting." ],
      [ "Nucleo Zenith", "ZENITH", "Jogadores de alto poder e prestígio." ],
      [ "Guarda Rubi", "RUBI", "Conteudo casual organizado." ],
      [ "Compasso Azul", "AZUL", "Rotas, mapas e missoes de campo." ],
      [ "Lanca Obsidiana", "OBS", "Operacoes especiais e bosses mundiais." ]
    ]
    squad_count = [ [ @user_count / 10, 3 ].max, squad_specs.size, @users.size - 1 ].min
    leaders = @users.drop(1).first(squad_count)

    leaders.each_with_index do |leader, index|
      name, tag, description = squad_specs[index]
      created_at = start_time + random.rand(0..8).days
      squad = guild.squads.create!(
        leader: leader,
        name: name,
        tag: tag,
        description: description,
        emblem_status: %w[approved approved pending rejected none][index % 5],
        emblem_uploaded_by: leader,
        emblem_reviewed_by: index % 5 == 3 ? admin : nil,
        emblem_reviewed_at: index % 5 == 3 ? created_at + 2.days : nil,
        emblem_rejection_reason: index % 5 == 3 ? "Imagem com baixa resolucao para a vitrine." : nil,
        profile_change_status: squad_profile_status(index),
        pending_profile_changes: squad_pending_changes(index, name, tag),
        profile_change_requested_at: index.in?([ 1, 2 ]) ? created_at + 10.days : nil,
        profile_change_reviewed_by: index == 2 ? admin : nil,
        profile_change_reviewed_at: index == 2 ? created_at + 11.days : nil,
        profile_change_rejection_reason: index == 2 ? "Sigla conflita com outro squad da comunidade." : nil,
        last_profile_change_approved_at: index.zero? ? created_at + 12.days : nil
      )
      stamp!(squad, created_at)
      leader.update!(squad: squad)
      @squads << squad
    end

    assignable_members = @users.drop(1)
    unsquadded_target = [ @user_count / 8, 6 ].max
    assign_count = [ assignable_members.size - unsquadded_target, @squads.size ].max
    assignable_members.first(assign_count).each_with_index do |user, index|
      user.update!(squad: @squads[index % @squads.size])
    end
  end

  def squad_profile_status(index)
    return "pending" if index == 1
    return "rejected" if index == 2
    return "approved" if index == 3

    "none"
  end

  def squad_pending_changes(index, name, tag)
    return { "name" => "#{name} Prime", "tag" => "#{tag}1", "description" => "Reposicionamento competitivo." } if index == 1

    {}
  end

  def create_squad_invitations!
    return if @squads.empty?

    unsquadded = @users.reject { |user| user == admin || user.squad_id.present? }
    statuses = %i[accepted declined pending revoked expired pending declined accepted revoked expired]

    statuses.each_with_index do |status, index|
      invitee = unsquadded.shift
      break unless invitee

      squad = @squads[index % @squads.size]
      invited_at = start_time + random.rand(7..27).days
      invitation = SquadInvitation.create!(
        squad: squad,
        inviter: squad.leader,
        invitee: invitee,
        note: "Convite mock para compor #{squad.name}.",
        expires_at: invited_at + SquadInvitation::INVITATION_TTL
      )

      case status
      when :accepted
        invitation.accept!(user: invitee, accepted_at: invited_at + 1.day)
      when :declined
        invitation.decline!(user: invitee, declined_at: invited_at + 1.day)
      when :revoked
        invitation.update!(status: "revoked", responded_at: invited_at + 1.day)
      when :expired
        invitation.update!(status: "expired", expires_at: invited_at - 1.hour, responded_at: invited_at)
      end
      stamp!(invitation, invited_at)
    end
  end

  def create_game_characters!
    classes = %w[Guardiao Arcanista Bardo Sentinela Duelista Clerigo Patrulheiro Ferreiro Cronista]
    builds = %w[Tank Suporte Dano Controle Hibrido Mobilidade Crafting Exploracao]

    @users.each_with_index do |user, index|
      character_count = index.zero? ? 2 : 1 + (index % 4 == 0 ? 1 : 0) + (index % 15 == 0 ? 1 : 0)
      character_count.times do |character_index|
        character_class = classes[(index + character_index) % classes.size]
        created_at = user.created_at + random.rand(0..8).days
        character = user.game_characters.create!(
          nickname: character_index.zero? ? "#{user.discord_nickname} Prime" : "#{user.discord_nickname} Alt #{character_index}",
          level: [ 1, 20 + ((index * 3 + character_index * 7) % 75) ].max,
          power: 8_000 + (index * 415) + random.rand(0..12_000) + character_index * 1_500,
          is_primary: character_index.zero?,
          character_data: {
            "class" => character_class,
            "build" => builds[(index + character_index * 2) % builds.size],
            "gear_score" => 500 + (index * 13) + random.rand(0..300),
            "healer" => character_class == "Clerigo"
          }
        )
        stamp!(character, created_at)
      end
    end
  end

  def create_achievements!
    achievement_specs = [
      [ :welcome, "boas_vindas", "Boas-vindas", "Primeira recompensa por atividade.", "Onboarding", { "min_xp" => 1 }, 40, 20, "#38BDF8" ],
      [ :event_regular, "presenca_eventos", "Presenca em Eventos", "Participou de pelo menos 5 eventos.", "Eventos", { "event_participated_count" => 5 }, 120, 60, "#22C55E" ],
      [ :mission_runner, "executor_missoes", "Executor de Missoes", "Recebeu recompensa em 3 missoes.", "Missoes", { "mission_rewarded_count" => 3 }, 140, 75, "#F59E0B" ],
      [ :rich, "tesouro_pessoal", "Tesouro Pessoal", "Acumulou saldo alto de moedas.", "Economia", { "min_currency_balance" => 1_200 }, 80, 40, nil ],
      [ :level_5, "nivel_5", "Ascensao Inicial", "Alcancou nivel 5.", "Progressao", { "min_level" => 5 }, 160, 80, "#A855F7" ],
      [ :level_8, "nivel_8", "Veterano da Aurora", "Alcancou nivel 8.", "Progressao", { "min_level" => 8 }, 220, 100, "#F97316" ],
      [ :high_xp, "xp_3000", "Fama Crescente", "Acumulou 3000 XP.", "Progressao", { "min_xp" => 3_000 }, 180, 90, nil ],
      [ :collector, "colecionador_certificados", "Colecionador", "Conquista manual para colecionadores.", "Colecao", {}, 60, 30, nil ],
      [ :individual_mv, "mvp_raid_maio", "MVP da Raid de Maio", "Reconhecimento individual por lideranca em raid.", "Individual", {}, 250, 120, nil, "individual" ],
      [ :individual_mentor, "mentor_da_semana", "Mentor da Semana", "Reconhecimento individual por ajudar recrutas.", "Individual", {}, 180, 90, nil, "individual" ]
    ]

    achievement_specs.each_with_index do |spec, index|
      key, code, name, description, category, criteria, xp, currency, color, achievement_type = spec
      @achievements[key] = guild.achievements.create!(
        code: code,
        name: name,
        description: description,
        category: category,
        criteria: criteria,
        reward_xp: xp,
        reward_currency: currency,
        reward_profile_name_color: color,
        achievement_type: achievement_type || "predefined",
        visibility: achievement_type == "individual" ? "profile_only" : "catalog",
        active: true
      )
      stamp!(@achievements[key], start_time + index.hours)
    end
  end

  def create_certificates!
    certificate_specs = [
      [ :raid, "cert_lider_raid", "Certificado de Lideranca de Raid", "Apto a liderar fechamento de evento.", "Eventos", @roles[:cert_raid] ],
      [ :craft, "cert_artesao", "Certificado de Artesao", "Reconhece dominio de crafting e economia.", "Crafting", @roles[:cert_crafter] ],
      [ :arena, "cert_arena", "Certificado de Arena", "Reconhece desempenho em PvP.", "PvP", @roles[:cert_pvp] ],
      [ :lore, "cert_cronista", "Certificado de Cronista", "Reconhece contribuicao de guias e documentacao.", "Conhecimento", @roles[:cert_lore] ],
      [ :mentor, "cert_mentor", "Certificado de Mentoria", "Apto a orientar novos membros.", "Mentoria", @roles[:cosmetic_elite] ],
      [ :founder, "cert_fundador_mock", "Certificado Fundador Mock", "Marca historica para membros pioneiros da demo.", "Historico", @roles[:cosmetic_founder] ]
    ]

    certificate_specs.each_with_index do |(key, code, name, description, category, role), index|
      @certificates[key] = guild.certificates.create!(
        code: code,
        name: name,
        description: description,
        category: category,
        role: role,
        active: true
      )
      stamp!(@certificates[key], start_time + index.hours)
    end

    RoleCertificateRequirement.create!(role: @roles[:raid_leader], certificate: @certificates[:raid])
    RoleCertificateRequirement.create!(role: @roles[:artisan], certificate: @certificates[:craft])
    RoleCertificateRequirement.create!(role: @roles[:mentor], certificate: @certificates[:mentor])
  end

  def create_missions!
    mission_specs = [
      [ :raid_report, "Relatorio de Raid", "Enviar print ou resumo de raid concluida.", "manual", "weekly", "fixed", 180, 90, 0, 0, 3, {} ],
      [ :resource_run, "Coleta de Recursos", "Registrar rotas de coleta. Recompensa por lote.", "manual", "daily", "per_unit", 0, 0, 35, 18, 4, {} ],
      [ :mentor_shift, "Plantao de Mentoria", "Ajudar recrutas com builds, eventos ou acesso.", "manual", "weekly", "fixed", 220, 110, 0, 0, 2, {} ],
      [ :lore_guide, "Guia de Conhecimento", "Publicar guia curto para a comunidade.", "manual", "monthly", "fixed", 350, 160, 0, 0, 2, {} ],
      [ :auto_character, "Atualizar Personagem Principal", "Automatica ao atualizar status do personagem principal.", "automatic", "weekly", "fixed", 80, 35, 0, 0, 1, { "trigger" => AutomaticMissionEvaluator::PRIMARY_CHARACTER_UPDATED_TRIGGER } ],
      [ :auto_login, "Primeiro Login da Semana", "Automatica ao acessar a plataforma na semana.", "automatic", "weekly", "fixed", 60, 25, 0, 0, 1, { "trigger" => AutomaticMissionEvaluator::FIRST_LOGIN_OF_WEEK_TRIGGER } ],
      [ :auto_events, "Sequencia de Presenca", "Automatica ao acumular presencas em eventos.", "automatic", "weekly", "fixed", 120, 55, 0, 0, 2, { "trigger" => AutomaticMissionEvaluator::EVENT_ATTENDED_COUNT_TRIGGER, "min_count" => 4 } ],
      [ :auto_streak, "Sequencia de Missoes", "Automatica ao concluir varias missoes recompensadas.", "automatic", "weekly", "fixed", 130, 65, 0, 0, 1, { "trigger" => AutomaticMissionEvaluator::MISSION_COMPLETED_STREAK_TRIGGER, "min_count" => 3 } ]
    ]

    mission_specs.each_with_index do |spec, index|
      key, name, description, mission_type, frequency, reward_mode, xp, currency, xp_unit, currency_unit, max_count, metadata = spec
      @missions[key] = guild.missions.create!(
        name: name,
        description: description,
        mission_type: mission_type,
        frequency: frequency,
        reward_mode: reward_mode,
        reward_xp: xp,
        reward_currency: currency,
        reward_xp_per_unit: xp_unit,
        reward_currency_per_unit: currency_unit,
        max_submissions_per_period: max_count,
        metadata: metadata,
        active: true
      )
      stamp!(@missions[key], start_time + index.hours)
    end
  end

  def create_automatic_activity!
    auto_users = @users.drop(1).first([ @user_count / 2, 55 ].min)
    auto_users.each { |user| AutomaticMissionEvaluator.evaluate_first_login_of_week!(user: user) }

    @users.drop(1).last([ @user_count / 3, 40 ].min).each do |user|
      character = user.game_character
      next unless character

      character.update!(power: character.power + random.rand(200..900))
    end
  end

  def create_events!
    completed_count = [ [ @user_count / 5, 8 ].max, 18 ].min
    event_titles = [
      "Raid Abismo Carmesim", "Treino de Arena", "Defesa da Fortaleza", "Boss Mundial",
      "Caravana de Coleta", "Noite de Mentoria", "Exploracao de Reliquias", "Guerra de Territorio"
    ]

    completed_count.times do |index|
      event_time = start_time + (index * (28.0 / completed_count)).days + 20.hours
      event = guild.events.create!(
        creator: admin,
        title: "#{event_titles[index % event_titles.size]} ##{index + 1}",
        description: "Evento mock com RSVP, revisao e recompensa simulada.",
        event_type: %w[raid pvp defense gathering mentoring exploration][index % 6],
        starts_at: event_time,
        ends_at: event_time + 2.hours,
        recurrence: index % 6 == 0 ? "weekly" : "unique",
        reward_xp: 120 + (index % 5) * 30,
        reward_currency: 55 + (index % 4) * 20
      )
      prepare_event_responses!(event, index)
      event.complete_with_results!(results: event_results(event, index), actor: admin)
      stamp_event_activity!(event, event_time)
    end

    4.times do |index|
      starts_at = reference_time + (index + 1).days
      event = guild.events.create!(
        creator: admin,
        title: "Agenda Futura #{index + 1}",
        description: "Evento futuro para demonstrar confirmacoes abertas.",
        event_type: %w[raid pvp mentoring gathering][index],
        starts_at: starts_at,
        ends_at: starts_at + 90.minutes,
        recurrence: "unique",
        reward_xp: 150,
        reward_currency: 70
      )
      event.event_participations.limit(@user_count / 3).each_with_index do |participation, response_index|
        if response_index.even?
          participation.update!(rsvp_status: "confirmed", responded_at: reference_time - response_index.hours)
        else
          participation.update!(
            rsvp_status: "declined",
            justification: "Conflito com agenda pessoal.",
            responded_at: reference_time - response_index.hours
          )
        end
      end
    end

    2.times do |index|
      starts_at = reference_time - (index + 3).days
      event = guild.events.create!(
        creator: admin,
        title: "Evento Cancelado #{index + 1}",
        description: "Cancelado para demonstrar historico operacional.",
        event_type: "maintenance",
        starts_at: starts_at,
        ends_at: starts_at + 1.hour,
        recurrence: "unique",
        reward_xp: 100,
        reward_currency: 40
      )
      event.update!(status: "canceled")
    end
  end

  def prepare_event_responses!(event, event_index)
    event.event_participations.find_each.with_index do |participation, index|
      pattern = (index + event_index) % 10
      responded_at = event.starts_at - random.rand(2..72).hours

      if pattern <= 5
        participation.update!(rsvp_status: "confirmed", responded_at: responded_at)
      elsif pattern <= 7
        participation.update!(
          rsvp_status: "declined",
          justification: [ "Trabalho no horario.", "Viagem marcada.", "Sem conexao estavel." ][pattern - 6],
          responded_at: responded_at
        )
      end
    end
  end

  def event_results(event, event_index)
    event.event_participations.each_with_object({}).with_index do |(participation, results), index|
      results[participation.id] = final_status_for(participation, index + event_index)
    end
  end

  def final_status_for(participation, pattern)
    if participation.confirmed?
      pattern % 5 == 0 ? "absent" : "participated"
    elsif participation.declined?
      pattern % 3 == 0 ? "participated" : "justified"
    else
      pattern % 4 == 0 ? "participated" : "absent"
    end
  end

  def stamp_event_activity!(event, event_time)
    completion_time = event_time + 2.hours
    event.update_columns(created_at: event_time - 3.days, updated_at: completion_time)
    participation_ids = event.event_participations.pluck(:id)
    event.event_participations.update_all(created_at: event_time - 2.days, updated_at: completion_time)
    event.event_participations.where.not(rewarded_at: nil).update_all(rewarded_at: completion_time)
    CurrencyTransaction.where(reason_type: "Event", reason_id: event.id).update_all(created_at: completion_time, updated_at: completion_time)
    AuditLog.where(guild: guild, entity_type: "Event", entity_id: event.id).update_all(created_at: completion_time, updated_at: completion_time)
    AuditLog.where(guild: guild, entity_type: "EventParticipation", entity_id: participation_ids).update_all(created_at: completion_time, updated_at: completion_time)
  end

  def create_manual_mission_submissions!
    manual_missions = @missions.values.select(&:manual?)
    status_cycle = %w[rewarded rewarded approved rejected pending rewarded]

    @users.each_with_index do |user, user_index|
      next if user == admin && @user_count > 1

      submissions_count = 2 + (user_index % 4)
      submissions_count.times do |submission_index|
        mission = manual_missions[(user_index + submission_index) % manual_missions.size]
        submitted_at = start_time + random.rand(3..28).days + random.rand(0..22).hours
        period_reference = mission.current_period_reference(reference_time: submitted_at)
        sequence_key = [ mission.id, user.id, period_reference ]
        @submission_sequences[sequence_key] += 1
        next if @submission_sequences[sequence_key] > mission.max_submissions_per_period

        submission = MissionSubmission.create!(
          mission: mission,
          user: user,
          week_reference: period_reference,
          period_sequence: @submission_sequences[sequence_key],
          quantity: mission.per_unit? ? random.rand(1..4) : 1,
          status: "pending",
          submitted_at: submitted_at,
          answers_json: {
            "summary" => "Submissao mock de #{user.discord_username}",
            "channel" => "#missoes",
            "presentation_seed" => true
          }
        )
        attach_mock_proof!(submission, user_index, submission_index) if submission_index.even?

        status = status_cycle[(user_index + submission_index) % status_cycle.size]
        review_time = submitted_at + random.rand(3..36).hours
        apply_submission_status!(submission, status, review_time)
        stamp_submission_activity!(submission, submitted_at, review_time)
      end
    end
  end

  def attach_mock_proof!(submission, user_index, submission_index)
    submission.proof.attach(
      io: StringIO.new("Comprovante mock #{user_index}-#{submission_index}\nGerado para apresentacao.\n"),
      filename: "proof-#{user_index}-#{submission_index}.txt",
      content_type: "text/plain"
    )
  end

  def apply_submission_status!(submission, status, review_time)
    case status
    when "approved"
      submission.approve!(reviewer: admin, notes: "Aprovada para demonstracao em #{review_time.to_date}.")
    when "rejected"
      submission.reject!(reviewer: admin, notes: "Comprovante incompleto na simulacao.")
    when "rewarded"
      submission.approve!(reviewer: admin, notes: "Aprovada e recompensada na simulacao.")
      submission.reward!(reviewer: admin)
    end
  end

  def stamp_submission_activity!(submission, submitted_at, review_time)
    attributes = {
      created_at: submitted_at,
      updated_at: review_time,
      submitted_at: submitted_at
    }
    attributes[:reviewed_at] = review_time if submission.reviewed_at.present?
    attributes[:rewarded_at] = review_time + 15.minutes if submission.rewarded_at.present?
    submission.update_columns(attributes)
    AuditLog.where(guild: guild, entity_type: "MissionSubmission", entity_id: submission.id)
            .update_all(created_at: review_time, updated_at: review_time)
  end

  def create_mission_requests!
    requesters = @users.select { |user| user.roles.special.exists? }
    requesters = @users.drop(1) if requesters.empty?
    return if requesters.empty?

    titles = [
      "Criar missao de crafting raro", "Expedicao de reliquias", "Treino para recrutas",
      "Desafio de arena semanal", "Guia de boss mundial", "Rota de coleta segura"
    ]
    request_count = [ [ @user_count / 4, 6 ].max, 28 ].min

    request_count.times do |index|
      requested_at = start_time + random.rand(4..29).days
      request = guild.mission_requests.create!(
        requester: requesters[index % requesters.size],
        title: "#{titles[index % titles.size]} ##{index + 1}",
        description: "Pedido especial mock para transformar cargo especial em missao operavel.",
        metadata: { "presentation_seed" => true, "estimated_players" => 3 + (index % 8) },
        status: "pending"
      )

      case index % 4
      when 0
        request.approve!(reviewer: admin, notes: "Aprovado para a proxima janela operacional.")
      when 1
        request.reject!(reviewer: admin, notes: "Escopo precisa ser melhor detalhado.")
      end
      stamp!(request, requested_at)
    end
  end

  def create_certificate_grants!
    certs = @certificates.values
    return if certs.empty?

    @users.drop(1).each_with_index do |user, index|
      next unless index % 3 == 0 || index < 12

      certificate = certs[index % certs.size]
      granted_at = start_time + random.rand(5..28).days
      user_certificate = UserCertificate.create!(
        user: user,
        certificate: certificate,
        granted_by: admin,
        granted_at: granted_at,
        expires_at: index % 10 == 0 ? reference_time - random.rand(1..5).days : nil,
        status: "granted"
      )

      if index % 14 == 0
        user_certificate.revoke!(revoked_by: admin)
        user_certificate.update_columns(status: "revoked", updated_at: granted_at + 3.days)
      end
      stamp!(user_certificate, granted_at)
    end

    @users.drop(1).first(18).each_with_index do |user, index|
      achievement = index.even? ? @achievements[:individual_mv] : @achievements[:individual_mentor]
      next if user.achievements.exists?(achievement.id)

      earned_at = start_time + random.rand(12..29).days
      user_achievement = UserAchievement.create!(user: user, achievement: achievement, earned_at: earned_at)
      stamp!(user_achievement, earned_at)
    end
  end

  def create_store!
    create_store_items!
    create_store_orders!
  end

  def create_store_items!
    item_specs = [
      [ "Pocao de Presenca", "Consumiveis", 90, 80, "active" ],
      [ "Reset de Apelido Visual", "Cosmeticos", 220, nil, "active" ],
      [ "Banner de Perfil Solar", "Cosmeticos", 420, 35, "active" ],
      [ "Pedido de Crafting Raro", "Servicos", 650, 25, "active" ],
      [ "Mentoria Individual", "Servicos", 300, nil, "active" ],
      [ "Ticket Boss Mundial", "Eventos", 180, 50, "active" ],
      [ "Pacote de Emotes", "Cosmeticos", 260, 40, "active" ],
      [ "Prioridade em Fila de Raid", "Eventos", 750, 20, "active" ],
      [ "Caixa de Materiais", "Consumiveis", 140, 120, "active" ],
      [ "Titulo de Cronista", "Cosmeticos", 900, 10, "active" ],
      [ "Item Sazonal Encerrado", "Historico", 500, 0, "inactive" ],
      [ "Pacote Antigo de Arena", "Historico", 300, 0, "archived" ]
    ]

    item_specs.each_with_index do |(name, category, price, stock, status), index|
      item = guild.store_items.create!(
        name: name,
        category: category,
        description: "Item mock para demonstrar loja, estoque e fulfillment manual.",
        price: price,
        stock_quantity: stock,
        status: status,
        fulfillment_type: "manual"
      )
      stamp!(item, start_time + index.hours)
      @store_items << item
    end
  end

  def create_store_orders!
    purchasable_items = @store_items.select(&:active?)
    order_count = [ [ (@user_count * 0.85).round, 10 ].max, 85 ].min
    buyers = @users.drop(1)
    return if buyers.empty?

    order_count.times do |index|
      buyer = buyers[index % buyers.size]
      item = purchasable_items[index % purchasable_items.size]
      buyer.update_columns(currency_balance: item.price + 500) if buyer.currency_balance < item.price

      order_time = start_time + random.rand(8..29).days + random.rand(0..20).hours
      order = StoreOrder.checkout!(user: buyer, store_item: item)

      case index % 5
      when 0
        order.fulfill!(actor: admin, notes: "Entregue manualmente no Discord.")
      when 1
        order.reject!(actor: admin, notes: "Item indisponivel no momento da revisao.")
      when 2
        order.cancel!(actor: buyer)
      end

      stamp_order_activity!(order, order_time)
    end
  end

  def stamp_order_activity!(order, order_time)
    status_time = order_time + random.rand(2..36).hours
    attributes = {
      created_at: order_time,
      updated_at: order.pending? ? order_time : status_time
    }
    attributes[:fulfilled_at] = status_time if order.fulfilled?
    attributes[:rejected_at] = status_time if order.rejected?
    attributes[:canceled_at] = status_time if order.canceled?
    attributes[:refunded_at] = status_time if order.refunded_at.present?
    order.update_columns(attributes)
    CurrencyTransaction.where(reason_type: "StoreOrder", reason_id: order.id)
                       .update_all(created_at: status_time, updated_at: status_time)
    AuditLog.where(guild: guild, entity_type: "StoreOrder", entity_id: order.id)
            .update_all(created_at: status_time, updated_at: status_time)
  end

  def create_rankings!
    ranking_specs = [
      [ "Top Nivel", "users", "user_level", 1 ],
      [ "Top XP", "users", "user_xp", 2 ],
      [ "Top Moedas Ganhas", "users", "user_currency_earned", 3 ],
      [ "Poder do Personagem", "users", "user_primary_character_power", 4 ],
      [ "Squads por XP", "squads", "squad_total_xp", 5 ],
      [ "Squads por Media de Nivel", "squads", "squad_average_level", 6 ],
      [ "Squads por Membros", "squads", "squad_members_count", 7 ]
    ]

    ranking_specs.each do |name, scope, metric, position|
      ranking = guild.rankings.create!(
        name: name,
        description: "Ranking mock calculado com dados de 30 dias.",
        ranking_scope: scope,
        metric: metric,
        sort_direction: "desc",
        entries_limit: 15,
        position: position,
        active: true
      )
      stamp!(ranking, start_time + position.hours)
    end
  end

  def create_audit_trail!
    30.times do |day|
      activity_time = start_time + day.days + 9.hours
      @users.shuffle(random: random).first([ @users.size, 8 ].min).each do |user|
        AuditLog.create!(
          user: user,
          guild: guild,
          action: day.even? ? "user_login" : "discord_roles_synced",
          entity_type: "User",
          entity_id: user.id,
          metadata: {
            "origin" => day.even? ? "user" : "job",
            "result" => "success",
            "presentation_day" => day + 1
          },
          created_at: activity_time + random.rand(0..8).hours,
          updated_at: activity_time + random.rand(0..8).hours
        )
      end
    end
  end

  def stamp!(record, timestamp)
    attributes = {}
    attributes[:created_at] = timestamp if record.has_attribute?(:created_at)
    attributes[:updated_at] = timestamp if record.has_attribute?(:updated_at)
    record.update_columns(attributes) if attributes.any?
  end

  def summary
    {
      guild_id: guild.id,
      guild_name: guild.name,
      users: guild.users.count,
      roles: guild.roles.count,
      permission_groups: guild.permission_groups.count,
      squads: guild.squads.count,
      squad_invitations: SquadInvitation.joins(:squad).where(squads: { guild_id: guild.id }).count,
      game_characters: GameCharacter.joins(:user).where(users: { guild_id: guild.id }).count,
      events: guild.events.count,
      event_participations: EventParticipation.joins(:event).where(events: { guild_id: guild.id }).count,
      missions: guild.missions.count,
      mission_submissions: MissionSubmission.joins(:mission).where(missions: { guild_id: guild.id }).count,
      mission_requests: guild.mission_requests.count,
      achievements: guild.achievements.count,
      user_achievements: UserAchievement.joins(:achievement).where(achievements: { guild_id: guild.id }).count,
      certificates: guild.certificates.count,
      user_certificates: UserCertificate.joins(:certificate).where(certificates: { guild_id: guild.id }).count,
      store_items: guild.store_items.count,
      store_orders: StoreOrder.joins(:store_item).where(store_items: { guild_id: guild.id }).count,
      rankings: guild.rankings.count,
      currency_transactions: CurrencyTransaction.joins(:user).where(users: { guild_id: guild.id }).count,
      audit_logs: AuditLog.where(guild: guild).count
    }
  end
end
