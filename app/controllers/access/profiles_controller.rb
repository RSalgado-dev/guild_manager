module Access
  # Controller para gerenciar o perfil do usuário
  class ProfilesController < AccessController
    before_action :load_user_context
    before_action :load_profile_data, only: [ :show ]

    def show
      # Página de perfil do usuário
    end

    def edit
      # Formulário de edição de perfil
    end

    def update
      # Atualização de perfil
      # Valida email antes de atualizar se foi fornecido
      if user_profile_params[:email].present? && user_profile_params[:email].blank?
        flash.now[:alert] = "❌ Erro ao atualizar perfil: Email não pode ficar em branco"
        render :edit, status: :unprocessable_entity
      elsif @user.update(user_profile_params)
        redirect_to profile_path, notice: "✅ Perfil atualizado com sucesso!"
      else
        flash.now[:alert] = "❌ Erro ao atualizar perfil: #{@user.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def user_profile_params
      # Permite apenas campos que o usuário pode editar
      params.require(:user).permit(:email, :discord_nickname)
    end

    def load_profile_data
      # Carrega dados completos do perfil com eager loading
      @user_roles = @user.user_roles.includes(:role)
      @achievements = @user.user_achievements.includes(:achievement)
      @certificates = @user.user_certificates.includes(:certificate)
      @recent_events = @user.event_participations.includes(:event).order(created_at: :desc).limit(5)
    end
  end
end
