# Controller base para área de acesso (usuários logados)
# Todos os controllers dentro do namespace Access herdam deste controller
class AccessController < ApplicationController
  before_action :require_login

  private

  def load_user_context
    @user = current_user
    @guild = current_user.guild
  end
end
