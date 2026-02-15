module Access
  # Controller para gerenciar o dashboard e páginas principais
  class DashboardController < AccessController
    skip_before_action :require_login, only: [ :index ]
    before_action :require_guild_access, only: [ :show ]
    before_action :load_user_context, only: [ :show, :restricted ]

    def index
      # Página inicial - mostra opções de login ou dashboard
      # Se o usuário já está logado e tem acesso, redireciona para o dashboard
      if has_guild_access?
        redirect_to dashboard_path
      end
    end

    def show
      # Dashboard principal para usuários autorizados
    end

    def restricted
      # Página de acesso restrito para usuários sem permissão de guild
    end
  end
end
