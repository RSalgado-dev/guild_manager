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
  get "/auth/discord", as: :discord_login
  get "/auth/discord/callback", to: "sessions#create"
  post "/auth/discord/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout

  # Rota de acesso restrito
  get "/restricted", to: "access#restricted", as: :restricted_access
  
  # Defines the root path route ("/")
  root "access#index"
end

