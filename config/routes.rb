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
  get "/restricted", to: "access/dashboard#restricted", as: :restricted_access

  # Dashboard para usuários com acesso
  get "/dashboard", to: "access/dashboard#show", as: :dashboard

  # Perfil do usuário
  get "/profile", to: "access/profiles#show", as: :profile
  get "/profile/edit", to: "access/profiles#edit", as: :edit_profile
  patch "/profile", to: "access/profiles#update", as: :update_profile

  # Personagens do jogo
  resources :characters,
            only: [ :new, :create, :edit, :update, :destroy ],
            controller: "access/characters"

  resources :events, controller: "access/events", only: [ :index, :show, :new, :create ] do
    member do
      patch :respond
      get :review
      patch :complete
    end
  end

  resources :squads, controller: "access/squads", only: [ :index, :show, :new, :create ] do
    member do
      patch :request_profile_change
      post :approve_profile_change
      post :reject_profile_change
      post :create_invitation
    end

    collection do
      get :pending_reviews
    end
  end

  resources :squad_invitations, controller: "access/squad_invitations", only: [] do
    member do
      post :accept
      post :decline
    end
  end

  # Defines the root path route ("/")
  root "access/dashboard#index"

  # ⚠️ APENAS DESENVOLVIMENTO - Remover em produção!
  if Rails.env.development?
    get "/dev/admin_login", to: "dev_sessions#admin_login", as: :dev_admin_login
    get "/dev/login", to: "dev_sessions#new", as: :dev_login
    post "/dev/login", to: "dev_sessions#create"
  end
end
