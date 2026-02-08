Rails.application.config.middleware.use OmniAuth::Builder do
  provider :discord,
           Rails.application.credentials.dig(:discord, :client_id),
           Rails.application.credentials.dig(:discord, :client_secret),
           scope: "identify guilds email"
end

# Configuração para lidar com falhas
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

# Desabilita get_request em produção para segurança
OmniAuth.config.allowed_request_methods = [ :post ] unless Rails.env.development?
