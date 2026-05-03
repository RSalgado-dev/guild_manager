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
      profile_params = user_profile_params

      if profile_params.key?(:email) && profile_params[:email].blank?
        flash.now[:alert] = "❌ Erro ao atualizar perfil: Email não pode ficar em branco"
        render :edit, status: :unprocessable_entity
      elsif @user.update(profile_params)
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
      @profile_name_color = @user.profile_name_color
      @achievements = @user.user_achievements.includes(:achievement).order(earned_at: :desc)
      @individual_achievements = @achievements.select(&:individual?)
      @certificates = @user.user_certificates.includes(certificate: :role).granted.select(&:active_certificate?)
      @recent_events = @user.event_participations.includes(:event).joins(:event).order("events.starts_at DESC").limit(5)
      @attendance_stats = @user.monthly_event_attendance_stats
    end
  end
end
