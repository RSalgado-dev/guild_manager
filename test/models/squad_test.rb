require "test_helper"

class SquadTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    squad = Squad.new(
      guild: guilds(:one),
      leader: users(:one),
      name: "Esquadrão de Teste",
      tag: "TESTE",
      description: "Um esquadrão para testes",
      emblem_status: :no_emblem
    )
    assert squad.valid?
  end

  test "não deve ser válido sem nome" do
    squad = Squad.new(
      guild: guilds(:one),
      leader: users(:one),
      tag: "NOMELESS",
      emblem_status: :none
    )
    assert_not squad.valid?
    assert_includes squad.errors[:name], "can't be blank"
  end

  test "não deve ser válido sem guilda" do
    squad = Squad.new(
      leader: users(:one),
      name: "Esquadrão sem guilda",
      tag: "SEMGLD",
      emblem_status: :no_emblem
    )
    assert_not squad.valid?
  end

  test "não deve ser válido sem líder" do
    squad = Squad.new(
      guild: guilds(:one),
      name: "Esquadrão sem líder",
      tag: "SEMLDR",
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
      name: "Novo Esquadrão",
      tag: "NOVO"
    )
    assert squad.valid?
  end

  test "deve verificar status de emblema" do
    squad_no_emblem = squads(:three)
    assert_equal "no_emblem", squad_no_emblem.emblem_status

    squad_approved = squads(:one)
    assert_equal "approved", squad_approved.emblem_status

    squad_pending = squads(:two)
    assert_equal "pending", squad_pending.emblem_status
  end

  test "deve normalizar tag em maiúsculo" do
    squad = Squad.new(guild: guilds(:one), leader: users(:one), name: "Teste", tag: "abc1")
    squad.valid?
    assert_equal "ABC1", squad.tag
  end

  test "líder pode solicitar alteração de perfil para revisão" do
    squad = squads(:one)
    squad.request_profile_change!(
      actor: squad.leader,
      attributes: { name: "Esquadrão Alpha 2", tag: "ALP2", description: "Nova descrição" }
    )

    assert squad.reload.profile_change_pending?
    assert_equal "Esquadrão Alpha 2", squad.pending_profile_changes["name"]
    assert_equal "ALP2", squad.pending_profile_changes["tag"]
  end

  test "aprovando alteração aplica novos dados e limpa pendência" do
    squad = squads(:one)
    reviewer = users(:two)
    squad.request_profile_change!(
      actor: squad.leader,
      attributes: { name: "Esquadrão Alpha 2", tag: "ALP2", description: "Nova descrição" }
    )

    squad.approve_profile_change!(reviewer: reviewer)
    squad.reload

    assert_equal "Esquadrão Alpha 2", squad.name
    assert_equal "ALP2", squad.tag
    assert_equal "profile_approved", squad.profile_change_status
    assert_equal({}, squad.pending_profile_changes)
  end

  test "alteração com emblema mantém preview pendente e promove imagem ao aprovar" do
    squad = squads(:one)
    reviewer = users(:two)

    squad.request_profile_change!(
      actor: squad.leader,
      attributes: {},
      emblem_file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/squad_emblem.png"), "image/png")
    )

    assert squad.reload.emblem_pending.attached?
    assert_not squad.emblem.attached?

    squad.approve_profile_change!(reviewer: reviewer)
    squad.reload

    assert squad.emblem.attached?
    assert_not squad.emblem_pending.attached?
    assert_equal "profile_approved", squad.profile_change_status
  end

  test "rejeitando alteração mantém dados atuais e registra motivo" do
    squad = squads(:one)
    reviewer = users(:two)
    original_name = squad.name
    squad.request_profile_change!(
      actor: squad.leader,
      attributes: { name: "Nome Rejeitado", tag: "RJT1" }
    )

    squad.reject_profile_change!(reviewer: reviewer, reason: "Fora do padrão")
    squad.reload

    assert_equal original_name, squad.name
    assert_equal "profile_rejected", squad.profile_change_status
    assert_equal "Fora do padrão", squad.profile_change_rejection_reason
  end
end
