require "test_helper"

class RankingCalculatorTest < ActiveSupport::TestCase
  test "calcula ranking de usuários por XP" do
    entries = rankings(:user_xp).entries

    assert_equal users(:one), entries.first.record
    assert_equal 100, entries.first.value
    assert_equal 1, entries.first.rank
  end

  test "calcula ranking de usuários por moedas ganhas" do
    entries = rankings(:user_currency).entries

    assert_equal users(:two), entries.first.record
    assert_equal 200, entries.first.value
    assert_equal users(:one), entries.second.record
    assert_equal 100, entries.second.value
  end

  test "calcula ranking de usuários por poder do personagem principal" do
    ranking = Ranking.create!(
      guild: guilds(:one),
      name: "Poder principal",
      ranking_scope: "users",
      metric: "user_primary_character_power",
      sort_direction: "desc",
      entries_limit: 5
    )

    entries = ranking.entries

    assert_equal users(:one), entries.first.record
    assert_equal 15_000, entries.first.value
  end

  test "calcula ranking de squads por total de XP" do
    ranking = Ranking.create!(
      guild: guilds(:one),
      name: "XP de squads",
      ranking_scope: "squads",
      metric: "squad_total_xp",
      sort_direction: "desc",
      entries_limit: 5
    )

    entries = ranking.entries

    assert_equal squads(:one), entries.first.record
    assert_equal 175, entries.first.value
  end

  test "calcula ranking de squads por média de nível" do
    ranking = Ranking.create!(
      guild: guilds(:one),
      name: "Média de nível",
      ranking_scope: "squads",
      metric: "squad_average_level",
      sort_direction: "desc",
      entries_limit: 5
    )

    entries = ranking.entries

    assert_equal squads(:one), entries.first.record
    assert_equal 0.3, entries.first.value
  end

  test "respeita ordenação ascendente e limite" do
    ranking = Ranking.create!(
      guild: guilds(:one),
      name: "Menor XP",
      ranking_scope: "users",
      metric: "user_xp",
      sort_direction: "asc",
      entries_limit: 1
    )

    entries = ranking.entries

    assert_equal 1, entries.size
    assert_equal users(:five), entries.first.record
  end
end
