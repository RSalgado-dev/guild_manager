class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def new
    # Página de login (se necessário)
  end

  def create
    auth = request.env["omniauth.auth"]

    # Debug em desenvolvimento
    if Rails.env.development?
      Rails.logger.info "=" * 80
      Rails.logger.info "Discord OAuth Callback"
      Rails.logger.info "Discord ID: #{auth.uid}"
      Rails.logger.info "Username: #{auth.info.name}"
      Rails.logger.info "Auth structure keys: #{auth.to_hash.keys}"
      Rails.logger.info "Credentials keys: #{auth.credentials&.keys}"
      Rails.logger.info "Access token presente: #{auth.credentials&.token.present?}"
      Rails.logger.info "Access token (10 primeiros chars): #{auth.credentials&.token&.[](0..10)}"
      Rails.logger.info "Extra keys: #{auth.extra&.keys}"
      Rails.logger.info "Raw info keys: #{auth.extra&.raw_info&.keys}"
      Rails.logger.info "Raw info: #{auth.extra&.raw_info&.to_hash&.except('guilds')}"
      Rails.logger.info "Guilds data: #{auth.extra&.raw_info&.guilds}"
      Rails.logger.info "Guilds do usuário: #{auth.extra&.raw_info&.guilds&.map { |g| "#{g['name']} (#{g['id']})" }&.join(', ')}"
      Rails.logger.info "=" * 80
    end

    user = User.find_or_create_from_discord(auth)

    if user.nil?
      Rails.logger.warn "Login falhou: Nenhum servidor Discord encontrado nas configurações"
      # Usuário não pertence a nenhuma guild configurada
      redirect_to root_path, alert: "❌ Nenhum servidor Discord encontrado. Você precisa estar em um servidor Discord autorizado para fazer login. Se você já autorizou este app antes, revogue a autorização nas configurações do Discord e tente novamente."
    elsif user.persisted?
      session[:user_id] = user.id
      Rails.logger.info "Login bem-sucedido: User ID #{user.id} (#{user.discord_username})"

      AuditLog.create(
        user: user,
        action: "login",
        metadata: {
          provider: "discord",
          discord_id: auth.uid,
          has_guild_access: user.has_guild_access
        }
      )

      # Redireciona baseado no acesso
      if user.has_guild_access
        redirect_to root_path, notice: "Login realizado com sucesso! Bem-vindo, #{user.discord_username}!"
      else
        redirect_to restricted_access_path, notice: "Login realizado, porém você não possui o cargo necessário para acessar os recursos internos."
      end
    else
      Rails.logger.error "Login falhou: User não foi persistido"
      redirect_to root_path, alert: "Não foi possível realizar o login. Tente novamente."
    end
  end

  def destroy
    if current_user
      AuditLog.create(
        user: current_user,
        action: "logout",
        metadata: { discord_id: current_user.discord_id }
      )
    end

    session[:user_id] = nil
    redirect_to root_path, notice: "Logout realizado com sucesso!"
  end

  def failure
    redirect_to root_path, alert: "Falha na autenticação: #{params[:message]}"
  end
end
