class DevSessionsController < ApplicationController
  # ⚠️ APENAS PARA DESENVOLVIMENTO! Remover em produção!
  skip_before_action :verify_authenticity_token, only: [ :create ]

  def new
    # Formulário de login
  end

  def create
    # Login rápido do usuário admin temporário ou por ID
    user = if params[:user_id].present?
             User.find_by(id: params[:user_id])
    else
             User.find_by(discord_id: "000000000000000000") # Admin temporário
    end

    if user
      session[:user_id] = user.id

      # Cria audit log
      AuditLog.create(
        user: user,
        guild: user.guild,
        action: "dev_login",
        entity_type: "User",
        entity_id: user.id
      )

      redirect_to admin_root_path, notice: "✅ Logado como: #{user.discord_username}"
    else
      redirect_to root_path, alert: "❌ Usuário não encontrado. Execute: bin/rails runner script/create_first_admin.rb"
    end
  end

  def admin_login
    # Login direto do admin temporário
    user = User.find_by(discord_id: "000000000000000000")

    unless user
      return redirect_to root_path, alert: "❌ Admin temporário não encontrado. Execute: bin/rails runner script/create_first_admin.rb"
    end

    session[:user_id] = user.id

    AuditLog.create(
      user: user,
      guild: user.guild,
      action: "dev_admin_login",
      entity_type: "User",
      entity_id: user.id
    )

    redirect_to admin_root_path, notice: "✅ Login admin dev realizado!"
  end
end
