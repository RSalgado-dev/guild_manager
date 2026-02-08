# frozen_string_literal: true

# Controller para lidar com rotas /auth que não são interceptadas pelo OmniAuth
# Exemplo: /auth sem provider especificado ou rotas inválidas
class AuthController < ApplicationController
  # Redireciona para a página inicial se /auth for acessado diretamente
  def index
    redirect_to root_path, alert: "Por favor, use um método de login válido."
  end

  # Ação padrão para rotas não encontradas sob /auth
  def default
    redirect_to root_path, alert: "Rota de autenticação não encontrada."
  end
end
