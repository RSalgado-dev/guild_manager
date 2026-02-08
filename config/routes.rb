Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Rotas de autenticação com Discord
  # OmniAuth intercepta automaticamente /auth/:provider como middleware
  # NÃO definir rota GET para /auth/discord pois interfere com OmniAuth
  get "/auth/discord/callback", to: "sessions#create"
  post "/auth/discord/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"

  # Fallback para /auth se acessado diretamente
  get "/auth", to: "auth#index"
  
  delete "/logout", to: "sessions#destroy", as: :logout

  # Rota de acesso restrito
  get "/restricted", to: "access#restricted", as: :restricted_access

  # Defines the root path route ("/")
  root "access#index"

  # ⚠️ APENAS DESENVOLVIMENTO - Remover em produção!
  if Rails.env.development?
    get "/dev/admin_login", to: "dev_sessions#admin_login", as: :dev_admin_login
    get "/dev/login", to: "dev_sessions#new", as: :dev_login
    post "/dev/login", to: "dev_sessions#create"
  end
end
