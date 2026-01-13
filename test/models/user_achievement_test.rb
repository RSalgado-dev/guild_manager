require "test_helper"

class UserAchievementTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    user_achievement = UserAchievement.new(
      user: users(:two),
      achievement: achievements(:one)
    )
    assert user_achievement.valid?
  end

  test "deve exigir user" do
    user_achievement = UserAchievement.new(achievement: achievements(:one))
    assert_not user_achievement.valid?
    assert_includes user_achievement.errors[:user], "must exist"
  end

  test "deve exigir achievement" do
    user_achievement = UserAchievement.new(user: users(:one))
    assert_not user_achievement.valid?
    assert_includes user_achievement.errors[:achievement], "must exist"
  end

  test "deve ser único por user_id e achievement_id" do
    existing = user_achievements(:one)
    duplicate = UserAchievement.new(
      user: existing.user,
      achievement: existing.achievement
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "mesmo usuário pode ter múltiplas conquistas diferentes" do
    user = users(:one)
    achievement1 = user_achievements(:one)
    achievement2 = user_achievements(:two)

    assert_equal user, achievement1.user
    assert_equal user, achievement2.user
    assert_not_equal achievement1.achievement, achievement2.achievement
  end

  # === Relacionamentos ===

  test "deve pertencer a um usuário" do
    user_achievement = user_achievements(:one)
    assert_respond_to user_achievement, :user
    assert_instance_of User, user_achievement.user
  end

  test "deve pertencer a uma conquista" do
    user_achievement = user_achievements(:one)
    assert_respond_to user_achievement, :achievement
    assert_instance_of Achievement, user_achievement.achievement
  end

  # === Callbacks ===

  test "deve definir earned_at automaticamente ao criar" do
    user_achievement = UserAchievement.new(
      user: users(:two),
      achievement: achievements(:three)
    )
    assert_nil user_achievement.earned_at

    user_achievement.save!
    assert_not_nil user_achievement.earned_at
    assert_in_delta Time.current, user_achievement.earned_at, 2.seconds
  end

  test "não deve sobrescrever earned_at se já estiver definido" do
    custom_time = 10.days.ago
    user_achievement = UserAchievement.new(
      user: users(:two),
      achievement: achievements(:three),
      earned_at: custom_time
    )
    user_achievement.save!
    assert_equal custom_time.to_i, user_achievement.earned_at.to_i
  end

  # === Source polymorphic ===

  test "pode ter source_type e source_id" do
    user_achievement = user_achievements(:one)
    assert_equal "Event", user_achievement.source_type
    assert_equal 1, user_achievement.source_id
  end

  test "source_type e source_id são opcionais" do
    user_achievement = UserAchievement.new(
      user: users(:two),
      achievement: achievements(:three)
    )
    assert user_achievement.valid?
    user_achievement.save!
    assert_nil user_achievement.source_type
    assert_nil user_achievement.source_id
  end
end
