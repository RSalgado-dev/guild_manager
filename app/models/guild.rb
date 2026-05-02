class Guild < ApplicationRecord
  DEFAULT_CHARACTER_TEMPLATE = [
    { "key" => "nickname", "label" => "Nickname", "field_type" => "string", "required" => true, "system" => true },
    { "key" => "level", "label" => "Nível", "field_type" => "integer", "required" => true, "system" => true },
    { "key" => "power", "label" => "Poder", "field_type" => "integer", "required" => true, "system" => true }
  ].freeze

  SYSTEM_CHARACTER_FIELD_KEYS = DEFAULT_CHARACTER_TEMPLATE.map { |field| field["key"] }.freeze

  has_many :users,          dependent: :destroy
  has_many :roles,          dependent: :destroy
  has_many :squads,         dependent: :destroy
  has_many :squad_invitations, through: :squads
  has_many :missions,       dependent: :destroy
  has_many :mission_requests, dependent: :destroy
  has_many :events,         dependent: :destroy
  has_many :achievements,   dependent: :destroy
  has_many :certificates,   dependent: :destroy
  has_many :permission_groups, dependent: :destroy
  has_many :rankings, dependent: :destroy

  before_validation :parse_character_template_json
  before_validation :ensure_default_character_template
  after_create :ensure_default_permission_group!

  validate :validate_character_template

  # Ransackers para busca no ActiveAdmin
  ransacker :users_count do
    query = "(SELECT COUNT(*) FROM users WHERE users.guild_id = guilds.id)"
    Arel.sql(query)
  end

  # Permitir busca por estes atributos no ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "character_template", "created_at", "description", "discord_guild_id", "discord_icon_url",
     "discord_name", "id", "name", "required_discord_role_id",
     "required_discord_role_name", "updated_at", "users_count" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "users", "roles", "squads", "missions", "events", "achievements", "certificates", "permission_groups" ]
  end

  validates :name,
            presence: true,
            length: { maximum: 100 }

  validates :discord_guild_id,
            presence: true,
            uniqueness: true

  # Encontra ou cria guilda a partir do ID do servidor Discord
  def self.find_or_create_from_discord(discord_guild_id, discord_name = nil, discord_icon_url = nil)
    guild = find_or_initialize_by(discord_guild_id: discord_guild_id)

    if guild.new_record?
      guild.name = discord_name || "Discord Guild #{discord_guild_id}"
      guild.discord_name = discord_name
      guild.discord_icon_url = discord_icon_url
      guild.save!
    elsif discord_name.present? || discord_icon_url.present?
      # Atualiza informações se fornecidas
      updates = {}
      updates[:discord_name] = discord_name if discord_name.present?
      updates[:discord_icon_url] = discord_icon_url if discord_icon_url.present?
      guild.update(updates) if updates.any?
    end

    guild
  end

  def character_template_fields
    return self.class.default_character_template if character_template.blank?

    normalize_character_template(character_template)
  rescue ArgumentError
    self.class.default_character_template
  end

  def self.default_character_template
    DEFAULT_CHARACTER_TEMPLATE.map(&:dup)
  end

  private

  def parse_character_template_json
    return unless character_template.is_a?(String)

    self.character_template = JSON.parse(character_template)
  rescue JSON::ParserError
    errors.add(:character_template, "deve estar em JSON válido")
  end

  def ensure_default_character_template
    self.character_template = self.class.default_character_template if character_template.blank?
  end

  def ensure_default_permission_group!
    permission_groups.find_or_create_by!(name: "Administração") do |group|
      group.description = "Grupo padrão com acesso total ao sistema."
      group.all_access = true
      group.permissions = PermissionGroup::AVAILABLE_PERMISSIONS
    end
  end

  def validate_character_template
    return if character_template.blank?

    normalized = normalize_character_template(character_template)
    field_keys = normalized.map { |field| field["key"] }

    if field_keys.uniq.size != field_keys.size
      errors.add(:character_template, "possui chaves duplicadas")
    end

    missing_system_keys = SYSTEM_CHARACTER_FIELD_KEYS - field_keys
    if missing_system_keys.any?
      errors.add(:character_template, "deve conter os campos base: #{missing_system_keys.join(', ')}")
    end

    normalized.each do |field|
      unless %w[string integer decimal boolean].include?(field["field_type"])
        errors.add(:character_template, "campo '#{field['key']}' possui tipo inválido")
      end
    end
  rescue ArgumentError => e
    errors.add(:character_template, e.message)
  end

  def normalize_character_template(value)
    unless value.is_a?(Array)
      raise ArgumentError, "deve ser um array de campos"
    end

    value.map do |field|
      unless field.is_a?(Hash)
        raise ArgumentError, "cada campo do template deve ser um objeto"
      end

      key = field["key"] || field[:key]
      label = field["label"] || field[:label]
      field_type = (field["field_type"] || field[:field_type] || "string").to_s
      required = field.key?("required") ? field["required"] : field[:required]
      required = true if required.nil?

      raise ArgumentError, "cada campo precisa de key" if key.blank?
      raise ArgumentError, "cada campo precisa de label" if label.blank?

      {
        "key" => key.to_s,
        "label" => label.to_s,
        "field_type" => field_type,
        "required" => ActiveModel::Type::Boolean.new.cast(required),
        "placeholder" => (field["placeholder"] || field[:placeholder]).to_s.presence,
        "help_text" => (field["help_text"] || field[:help_text]).to_s.presence,
        "system" => SYSTEM_CHARACTER_FIELD_KEYS.include?(key.to_s)
      }
    end
  end
end
