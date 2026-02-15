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

  # Unicidade
  test "should allow only one character per user" do
    @character.save!

    duplicate = GameCharacter.new(
      user: @user,
      nickname: "AnotherCharacter",
      level: 30,
      power: 500
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
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
end
