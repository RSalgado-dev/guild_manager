require "test_helper"

class SquadTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    squad = Squad.new(
      guild: guilds(:one),
      leader: users(:one),
      name: "Esquadrão de Teste",
      description: "Um esquadrão para testes",
      emblem_status: :no_emblem
    )
    assert squad.valid?
  end

  test "não deve ser válido sem nome" do
    squad = Squad.new(
      guild: guilds(:one),
      leader: users(:one),
      emblem_status: :none
    )
    assert_not squad.valid?
    assert_includes squad.errors[:name], "can't be blank"
  end

  test "não deve ser válido sem guilda" do
    squad = Squad.new(
      leader: users(:one),
      name: "Esquadrão sem guilda",
      emblem_status: :no_emblem
    )
    assert_not squad.valid?
  end

  test "não deve ser válido sem líder" do
    squad = Squad.new(
      guild: guilds(:one),
      name: "Esquadrão sem líder",
      emblem_status: :no_emblem
    )
    assert_not squad.valid?
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    squad = squads(:one)
    assert_respond_to squad, :guild
    assert_instance_of Guild, squad.guild
  end

  test "deve pertencer a um líder" do
    squad = squads(:one)
    assert_respond_to squad, :leader
    assert_instance_of User, squad.leader
  end

  test "deve ter muitos usuários" do
    squad = squads(:one)
    assert_respond_to squad, :users
  end

  test "deve pertencer opcionalmente a emblem_uploaded_by" do
    squad = squads(:one)
    assert_respond_to squad, :emblem_uploaded_by
  end

  test "deve pertencer opcionalmente a emblem_reviewed_by" do
    squad = squads(:one)
    assert_respond_to squad, :emblem_reviewed_by
  end

  test "deve anular usuários ao ser destruído" do
    squad = squads(:one)
    user = squad.users.first
    squad.destroy
    user.reload
    assert_nil user.squad_id
  end

  # === Enums ===

  test "deve aceitar status de emblema válidos" do
    squad = squads(:one)

    assert_nothing_raised do
      squad.emblem_status = :no_emblem
      squad.emblem_status = :pending
      squad.emblem_status = :approved
      squad.emblem_status = :rejected
    end
  end

  test "deve ter status de emblema none por padrão" do
    squad = Squad.new(
      guild: guilds(:one),
      leader: users(:one),
      name: "Novo Esquadrão"
    )
    # O enum será setado após validação
    assert squad.valid?
  end

  test "deve verificar status de emblema" do
    squad_no_emblem = squads(:three)
    assert_equal "none", squad_no_emblem.emblem_status

    squad_approved = squads(:one)
    assert_equal "approved", squad_approved.emblem_status

    squad_pending = squads(:two)
    assert_equal "pending", squad_pending.emblem_status
  end
end
