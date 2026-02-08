class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def new
    # Página de login (se necessário)
  end

  def create
    auth = request.env["omniauth.auth"]

    user = User.find_or_create_from_discord(auth)

    if user.nil?
      # Usuário não pertence a nenhuma guild configurada
      redirect_to root_path, alert: "Acesso negado. Você precisa estar em um servidor Discord autorizado para fazer login."
    elsif user.persisted?
      session[:user_id] = user.id

      AuditLog.create(
        user: user,
        action: "login",
        details: { 
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
      redirect_to root_path, alert: "Não foi possível realizar o login. Tente novamente."
    end
  end

  def destroy
    if current_user
      AuditLog.create(
        user: current_user,
        action: "logout",
        details: { discord_id: current_user.discord_id }
      )
    end

    session[:user_id] = nil
    redirect_to root_path, notice: "Logout realizado com sucesso!"
  end

  def failure
    redirect_to root_path, alert: "Falha na autenticação: #{params[:message]}"
  end
end
