require "test_helper"

class RankingTest < ActiveSupport::TestCase
  test "é válido com atributos válidos" do
    ranking = Ranking.new(
      guild: guilds(:one),
      name: "Poder dos personagens",
      ranking_scope: "users",
      metric: "user_primary_character_power",
      sort_direction: "desc",
      entries_limit: 10
    )

    assert ranking.valid?
  end

  test "metric precisa ser compatível com escopo de usuários" do
    ranking = rankings(:user_xp)
    ranking.metric = "squad_total_xp"

    assert_not ranking.valid?
    assert_includes ranking.errors[:metric], "não é compatível com o escopo selecionado"
  end

  test "metric precisa ser compatível com escopo de squads" do
    ranking = rankings(:squad_members)
    ranking.metric = "user_xp"

    assert_not ranking.valid?
    assert_includes ranking.errors[:metric], "não é compatível com o escopo selecionado"
  end

  test "entries_limit deve ser limitado" do
    ranking = rankings(:user_xp)
    ranking.entries_limit = 101

    assert_not ranking.valid?
  end

  test "metric_label retorna label humano" do
    assert_equal "XP", rankings(:user_xp).metric_label
    assert_equal "Número de membros", rankings(:squad_members).metric_label
  end
end
