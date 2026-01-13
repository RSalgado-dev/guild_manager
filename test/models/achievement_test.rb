require "test_helper"

class AchievementTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    achievement = Achievement.new(
      guild: guilds(:one),
      code: "test_achievement",
      name: "Test Achievement"
    )
    assert achievement.valid?
  end

  test "deve exigir code" do
    achievement = Achievement.new(
      guild: guilds(:one),
      name: "Test"
    )
    assert_not achievement.valid?
    assert_includes achievement.errors[:code], "can't be blank"
  end

  test "deve exigir name" do
    achievement = Achievement.new(
      guild: guilds(:one),
      code: "test"
    )
    assert_not achievement.valid?
    assert_includes achievement.errors[:name], "can't be blank"
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    achievement = achievements(:one)
    assert_respond_to achievement, :guild
    assert_instance_of Guild, achievement.guild
  end

  test "deve ter muitas user_achievements" do
    achievement = achievements(:one)
    assert_respond_to achievement, :user_achievements
  end

  test "deve ter muitos usuários através de user_achievements" do
    achievement = achievements(:one)
    assert_respond_to achievement, :users
  end

  test "deve destruir user_achievements ao ser destruído" do
    achievement = achievements(:one)
    user_achievement_count = achievement.user_achievements.count
    assert user_achievement_count > 0, "Deve ter pelo menos um user_achievement"

    assert_difference("UserAchievement.count", -user_achievement_count) do
      achievement.destroy
    end
  end

  # === Testes de unicidade ===

  test "code deve ser único por guilda" do
    existing = achievements(:one)
    duplicate = Achievement.new(
      guild: existing.guild,
      code: existing.code,
      name: "Different Name"
    )
    assert_not duplicate.valid?
  end

  test "code pode ser duplicado em guildas diferentes" do
    achievement_guild_one = achievements(:one)
    achievement_guild_two = Achievement.new(
      guild: guilds(:two),
      code: achievement_guild_one.code,
      name: "Same code, different guild"
    )
    assert achievement_guild_two.valid?
  end
end
