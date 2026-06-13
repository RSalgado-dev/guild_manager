module SystemAuthenticationHelper
  def system_sign_in(user, visit_after_sign_in: dashboard_path, ensure_guild_access: true)
    stub_discord_bot_token

    stub_discord_user_guilds(
      access_token: user.discord_access_token || "fake_token",
      guilds: [ { "id" => user.guild.discord_guild_id, "name" => user.guild.name } ]
    )

    synced_role_ids = ([ user.guild.required_discord_role_id ] + user.roles.pluck(:discord_role_id)).compact_blank.uniq
    stub_discord_guild_member(
      guild_id: user.guild.discord_guild_id,
      user_id: user.discord_id,
      roles: synced_role_ids
    )

    synced_guild_roles = user.roles.where.not(discord_role_id: nil).map do |role|
      {
        "id" => role.discord_role_id,
        "name" => role.name
      }
    end
    synced_guild_roles << {
      "id" => user.guild.required_discord_role_id,
      "name" => user.guild.required_discord_role_name || "Membro"
    }
    stub_discord_guild_roles(
      guild_id: user.guild.discord_guild_id,
      roles: synced_guild_roles.uniq { |role| role["id"] }
    )

    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
      provider: "discord",
      uid: user.discord_id,
      info: {
        name: user.discord_username,
        email: user.email || "system-#{user.id}@example.com",
        image: user.discord_avatar_url
      },
      credentials: {
        token: user.discord_access_token || "fake_token",
        refresh_token: user.discord_refresh_token || "fake_refresh_token",
        expires_at: 1.week.from_now.to_i
      }
    )

    visit "/auth/discord/callback"
    ensure_required_guild_role!(user.reload) if ensure_guild_access
    visit visit_after_sign_in if visit_after_sign_in
  end

  # Autentica via Discord sem o cargo requerido pela guild, para exercitar o
  # caminho de acesso negado: o callback registra a sessão mas mantém
  # has_guild_access falso, redirecionando o usuário para a página restrita.
  def system_sign_in_without_access(user)
    stub_discord_bot_token

    stub_discord_user_guilds(
      access_token: user.discord_access_token || "fake_token",
      guilds: [ { "id" => user.guild.discord_guild_id, "name" => user.guild.name } ]
    )

    # Sem nenhum cargo no Discord, inclusive sem o cargo requerido.
    stub_discord_guild_member(
      guild_id: user.guild.discord_guild_id,
      user_id: user.discord_id,
      roles: []
    )
    stub_discord_guild_roles(
      guild_id: user.guild.discord_guild_id,
      roles: []
    )

    OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
      provider: "discord",
      uid: user.discord_id,
      info: {
        name: user.discord_username,
        email: user.email || "system-#{user.id}@example.com",
        image: user.discord_avatar_url
      },
      credentials: {
        token: user.discord_access_token || "fake_token",
        refresh_token: user.discord_refresh_token || "fake_refresh_token",
        expires_at: 1.week.from_now.to_i
      }
    )

    visit "/auth/discord/callback"
  end

  private

  def ensure_required_guild_role!(user)
    return if user.guild.required_discord_role_id.blank?

    role = user.guild.roles.find_or_create_by!(discord_role_id: user.guild.required_discord_role_id) do |new_role|
      new_role.name = user.guild.required_discord_role_name || "Membro"
      new_role.description = new_role.name
      new_role.category = "base"
    end

    user.user_roles.find_or_create_by!(role: role)
    user.update_column(:has_guild_access, true)
  end
end
