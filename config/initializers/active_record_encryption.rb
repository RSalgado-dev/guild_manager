encryption_config = Rails.application.config.active_record.encryption
credentials = Rails.application.credentials.dig(:active_record_encryption) || {}

fetch_encryption_key = lambda do |env_key, credential_key, development_default|
  ENV[env_key].presence || credentials[credential_key].presence || begin
    raise KeyError, "#{env_key} ou credentials.active_record_encryption.#{credential_key} precisa ser configurado" if Rails.env.production?

    development_default
  end
end

encryption_config.primary_key = fetch_encryption_key.call(
  "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY",
  :primary_key,
  "guild-manager-dev-primary-key-32"
)
encryption_config.deterministic_key = fetch_encryption_key.call(
  "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY",
  :deterministic_key,
  "guild-manager-dev-determinist-key"
)
encryption_config.key_derivation_salt = fetch_encryption_key.call(
  "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT",
  :key_derivation_salt,
  "guild-manager-dev-key-salt-value"
)

encryption_config.support_unencrypted_data = true
encryption_config.extend_queries = true
