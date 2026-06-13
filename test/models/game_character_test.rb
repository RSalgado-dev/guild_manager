require "test_helper"

class GameCharacterTest < ActiveSupport::TestCase
  def setup
    # Criar um usuário novo sem personagem para os testes
    @guild = guilds(:one)
    @user = User.create!(
      guild: @guild,
      discord_id: "test_#{SecureRandom.hex(8)}",
      discord_username: "test_user",
      xp_points: 0,
      currency_balance: 0,
      has_guild_access: true
    )

    @character = GameCharacter.new(
      user: @user,
      nickname: "TestWarrior",
      level: 50,
      power: 1000
    )
  end

  # Validações básicas
  test "should be valid with valid attributes" do
    assert @character.valid?
  end

  test "first character should become primary automatically" do
    @character.save!
    assert @character.reload.is_primary?
  end

  test "should require nickname" do
    @character.nickname = nil
    assert_not @character.valid?
    assert_includes @character.errors[:nickname], "can't be blank"
  end

  test "should require level" do
    @character.level = nil
    assert_not @character.valid?
    assert_includes @character.errors[:level], "can't be blank"
  end

  test "should require power" do
    @character.power = nil
    assert_not @character.valid?
    assert_includes @character.errors[:power], "can't be blank"
  end

  # Validações de tamanho
  test "nickname should be at least 2 characters" do
    @character.nickname = "A"
    assert_not @character.valid?
    assert_includes @character.errors[:nickname], "is too short (minimum is 2 characters)"
  end

  test "nickname should not exceed 50 characters" do
    @character.nickname = "A" * 51
    assert_not @character.valid?
    assert_includes @character.errors[:nickname], "is too long (maximum is 50 characters)"
  end

  # Validações numéricas
  test "level should be greater than or equal to 1" do
    @character.level = 0
    assert_not @character.valid?
    assert_includes @character.errors[:level], "must be greater than or equal to 1"
  end

  test "level should be less than or equal to 999" do
    @character.level = 1000
    assert_not @character.valid?
    assert_includes @character.errors[:level], "must be less than or equal to 999"
  end

  test "power should be greater than or equal to 0" do
    @character.power = -1
    assert_not @character.valid?
    assert_includes @character.errors[:power], "must be greater than or equal to 0"
  end

  test "level should be an integer" do
    @character.level = 50.5
    assert_not @character.valid?
    assert_includes @character.errors[:level], "must be an integer"
  end

  test "power should be an integer" do
    @character.power = 1000.5
    assert_not @character.valid?
    assert_includes @character.errors[:power], "must be an integer"
  end

  # Relacionamentos
  test "should belong to user" do
    assert_respond_to @character, :user
    assert_equal @user, @character.user
  end

  test "should have one attached status_screenshot" do
    assert_respond_to @character, :status_screenshot
  end

  # Múltiplos personagens por usuário
  test "should allow more than one character per user" do
    @character.save!

    second_character = GameCharacter.new(
      user: @user,
      nickname: "AnotherCharacter",
      level: 30,
      power: 500
    )

    assert second_character.valid?
  end

  test "user cannot end up without a primary character" do
    @character.save!

    second_character = GameCharacter.new(
      user: @user,
      nickname: "SecondOne",
      level: 35,
      power: 700
    )

    assert_not @character.update(is_primary: false)
    assert_includes @character.errors[:is_primary], "deve ter um personagem principal"
    assert second_character.valid?
  end

  test "promoting one character should demote previous primary" do
    @character.save!
    second_character = GameCharacter.create!(
      user: @user,
      nickname: "SecondOne",
      level: 35,
      power: 700
    )

    second_character.update!(is_primary: true)
    assert second_character.reload.is_primary?
    assert_not @character.reload.is_primary?
  end

  test "destroying primary should promote another character" do
    @character.save!
    second_character = GameCharacter.create!(
      user: @user,
      nickname: "SecondOne",
      level: 35,
      power: 700
    )

    @character.destroy!
    assert second_character.reload.is_primary?
  end

  test "should allow characters for different users" do
    @character.save!

    other_user = User.create!(
      guild: @guild,
      discord_id: "other_#{SecureRandom.hex(8)}",
      discord_username: "other_user",
      xp_points: 0,
      currency_balance: 0,
      has_guild_access: true
    )

    other_character = GameCharacter.new(
      user: other_user,
      nickname: "OtherWarrior",
      level: 40,
      power: 800
    )

    assert other_character.valid?
  end

  # Ransackable
  test "should define ransackable_attributes" do
    assert_includes GameCharacter.ransackable_attributes, "nickname"
    assert_includes GameCharacter.ransackable_attributes, "level"
    assert_includes GameCharacter.ransackable_attributes, "power"
    assert_includes GameCharacter.ransackable_attributes, "character_data"
    assert_includes GameCharacter.ransackable_attributes, "is_primary"
  end

  test "should define ransackable_associations" do
    assert_includes GameCharacter.ransackable_associations, "user"
  end

  # Edge cases
  test "should accept minimum valid level" do
    @character.level = 1
    assert @character.valid?
  end

  test "should accept maximum valid level" do
    @character.level = 999
    assert @character.valid?
  end

  test "should accept zero power" do
    @character.power = 0
    assert @character.valid?
  end

  test "should accept very large power values" do
    @character.power = 999_999_999
    assert @character.valid?
  end

  test "nickname should accept valid characters" do
    valid_names = [ "Warrior123", "Dark_Knight", "Mage-Pro", "龍の戦士" ]

    valid_names.each do |name|
      @character.nickname = name
      assert @character.valid?, "#{name} should be valid"
    end
  end

  test "should require template custom field when marked as required" do
    @guild.update!(
      character_template: [
        { key: "nickname", label: "Nickname", field_type: "string", required: true },
        { key: "level", label: "Nível", field_type: "integer", required: true },
        { key: "power", label: "Poder", field_type: "integer", required: true },
        { key: "classe", label: "Classe", field_type: "string", required: true }
      ]
    )

    @character.character_data = {}
    assert_not @character.valid?
    assert_includes @character.errors.full_messages.join, "Classe é obrigatório"
  end

  test "should accept template custom field with valid value" do
    @guild.update!(
      character_template: [
        { key: "nickname", label: "Nickname", field_type: "string", required: true },
        { key: "level", label: "Nível", field_type: "integer", required: true },
        { key: "power", label: "Poder", field_type: "integer", required: true },
        { key: "classe", label: "Classe", field_type: "string", required: true }
      ]
    )

    @character.character_data = { "classe" => "Arqueiro" }
    assert @character.valid?
  end

  test "status screenshot must be an allowed image type" do
    @character.status_screenshot.attach(
      io: StringIO.new("not an image"),
      filename: "status.txt",
      content_type: "text/plain"
    )

    assert_not @character.valid?
    assert_includes @character.errors[:status_screenshot], "deve ser uma imagem (JPEG, PNG ou WEBP)"
  end

  test "status screenshot must be at most five megabytes" do
    @character.status_screenshot.attach(
      io: StringIO.new("x" * (5.megabytes + 1)),
      filename: "status.png",
      content_type: "image/png"
    )

    assert_not @character.valid?
    assert_includes @character.errors[:status_screenshot], "deve ter no máximo 5MB"
  end

  test "template custom fields reject unknown keys" do
    @guild.update!(
      character_template: [
        { key: "nickname", label: "Nickname", field_type: "string", required: true },
        { key: "level", label: "Nível", field_type: "integer", required: true },
        { key: "power", label: "Poder", field_type: "integer", required: true },
        { key: "classe", label: "Classe", field_type: "string", required: false }
      ]
    )

    @character.character_data = { "classe" => "Arqueiro", "forbidden" => "x" }

    assert_not @character.valid?
    assert_includes @character.errors[:character_data], "possui campos não permitidos: forbidden"
  end

  test "template custom fields validate integer decimal and boolean values" do
    @guild.update!(
      character_template: [
        { key: "nickname", label: "Nickname", field_type: "string", required: true },
        { key: "level", label: "Nível", field_type: "integer", required: true },
        { key: "power", label: "Poder", field_type: "integer", required: true },
        { key: "gear_score", label: "Gear Score", field_type: "integer", required: true },
        { key: "crit_rate", label: "Taxa Crítica", field_type: "decimal", required: true },
        { key: "support", label: "Suporte", field_type: "boolean", required: true }
      ]
    )

    @character.character_data = {
      "gear_score" => "abc",
      "crit_rate" => "muito",
      "support" => "talvez"
    }

    assert_not @character.valid?
    assert_includes @character.errors.full_messages.join, "Gear Score deve ser inteiro"
    assert_includes @character.errors.full_messages.join, "Taxa Crítica deve ser numérico"
    assert_includes @character.errors.full_messages.join, "Suporte deve ser verdadeiro ou falso"

    @character.character_data = {
      "gear_score" => "750",
      "crit_rate" => "12.5",
      "support" => "false"
    }

    assert @character.valid?
  end
end
