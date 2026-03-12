# Controller base para área de acesso (usuários logados)
# Todos os controllers dentro do namespace Access herdam deste controller
class AccessController < ApplicationController
  before_action :require_login
  before_action :refresh_discord_roles_cache

  private

  def load_user_context
    @user = current_user
    @guild = current_user.guild
  end

  def refresh_discord_roles_cache
    return unless current_user

    current_user.sync_discord_roles_if_stale!(max_age: User::DISCORD_ROLE_SYNC_MAX_AGE)
  end
end
