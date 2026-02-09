# Configuração do OmniAuth para autenticação Discord
#
# O OmniAuth funciona como middleware Rack que intercepta rotas /auth/:provider
# automaticamente. NÃO defina rotas explícitas para /auth/discord no routes.rb
# pois isso impede o OmniAuth de funcionar corretamente.
#
# Fluxo de autenticação:
# 1. Usuário acessa /auth/discord (interceptado pelo OmniAuth)
# 2. OmniAuth redireciona para Discord OAuth
# 3. Usuário autoriza no Discord
# 4. Discord redireciona para /auth/discord/callback
# 5. SessionsController#create processa os dados
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :discord,
           Rails.application.credentials.dig(:discord, :client_id),
           Rails.application.credentials.dig(:discord, :client_secret),
           scope: "identify guilds email",
           request_options: {
             fetch_guilds: true
           }
end

# Configuração para lidar com falhas
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

# Permite GET e POST em desenvolvimento, apenas POST em produção
if Rails.env.development?
  OmniAuth.config.allowed_request_methods = [ :get, :post ]
else
  OmniAuth.config.allowed_request_methods = [ :post ]
end
