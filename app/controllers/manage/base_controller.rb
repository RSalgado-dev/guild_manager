# frozen_string_literal: true

module Manage
  class BaseController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :require_manage_area_access!

    private

    def require_manage_area_access!
      return if current_user.manage_area_access?

      redirect_to dashboard_path, alert: "❌ Você não tem acesso à área de gestão."
    end

    def require_manage_permission!(permission_key)
      return if current_user.has_permission?(permission_key)

      redirect_to manage_root_path, alert: "❌ Você não tem permissão para este módulo."
    end
  end
end
