class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :has_guild_access?, :has_permission?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def has_guild_access?
    logged_in? && current_user.has_guild_access?
  end

  def has_permission?(permission_key)
    logged_in? && current_user.has_permission?(permission_key)
  end

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "Você precisa estar logado para acessar esta página."
    end
  end

  def require_guild_access
    unless has_guild_access?
      if logged_in?
        redirect_to restricted_access_path
      else
        redirect_to root_path, alert: "Você precisa estar logado para acessar esta página."
      end
    end
  end

  def require_admin
    unless logged_in?
      redirect_to root_path, alert: "Você precisa estar logado para acessar esta página."
      return
    end

    unless current_user.admin?
      redirect_to root_path, alert: "❌ Acesso negado. Você não tem permissão para acessar o painel administrativo."
    end
  end

  def require_permission(permission_key)
    refresh_discord_roles_for_permission_check!
    return if has_permission?(permission_key)

    redirect_to root_path, alert: "❌ Acesso negado. Você não possui a permissão necessária."
  end

  def refresh_discord_roles_for_permission_check!
    return unless logged_in?
    return if @discord_roles_refreshed_for_permission

    current_user.sync_discord_roles_if_stale!(max_age: User::PERMISSION_CHECK_SYNC_MAX_AGE)
    @discord_roles_refreshed_for_permission = true
  end
end
