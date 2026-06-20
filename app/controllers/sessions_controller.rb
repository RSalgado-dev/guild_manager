class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def new
    # Página de login (se necessário)
  end

  def create
    auth = request.env["omniauth.auth"]

    if Rails.env.development? && ENV["DISCORD_DEBUG"].present?
      Rails.logger.info "=" * 80
      Rails.logger.info "Discord OAuth Callback"
      Rails.logger.info "Discord ID: #{auth.uid}"
      Rails.logger.info "Username: #{auth.info.name}"
      Rails.logger.info "Auth structure keys: #{auth.to_hash.keys}"
      Rails.logger.info "Access token presente: #{auth.credentials&.token.present?}"
      Rails.logger.info "Refresh token presente: #{auth.credentials&.refresh_token.present?}"
      Rails.logger.info "OmniAuth state presente: #{request.env['omniauth.state'].present?}"
      Rails.logger.info "=" * 80
    end

    user = User.find_or_create_from_discord(auth)

    if user.nil?
      Rails.logger.warn "Login falhou: Nenhum servidor Discord encontrado nas configurações"
      # Usuário não pertence a nenhuma guild configurada
      redirect_to root_path, alert: "Nenhum servidor Discord encontrado. Você precisa estar em um servidor Discord autorizado para entrar. Se você já autorizou este app antes, revogue a autorização nas configurações do Discord e tente novamente."
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
      AutomaticMissionEvaluator.evaluate_first_login_of_week!(user: user) if user.has_guild_access

      # Redireciona baseado no acesso
      if user.has_guild_access
        redirect_to root_path, notice: "Entrada realizada com sucesso. Bem-vindo, #{user.discord_username}!"
      else
        redirect_to restricted_access_path, notice: "Entrada realizada, porém você não possui o cargo necessário para acessar os recursos internos."
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
    redirect_to root_path, notice: "Saída realizada com sucesso."
  end

  def failure
    redirect_to root_path, alert: "Falha na autenticação: #{params[:message]}"
  end
end
