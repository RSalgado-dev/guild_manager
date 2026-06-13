require "test_helper"

class MissionRequestTest < ActiveSupport::TestCase
  test "é válido com atributos válidos" do
    request = MissionRequest.new(
      guild: guilds(:one),
      requester: users(:one),
      title: "Coletar minério",
      description: "Precisamos de materiais para craft."
    )

    assert request.valid?
  end

  test "requester deve pertencer à guilda" do
    request = MissionRequest.new(
      guild: guilds(:one),
      requester: users(:three),
      title: "Pedido inválido",
      description: "Outra guilda."
    )

    assert_not request.valid?
    assert_includes request.errors[:requester], "deve pertencer à guilda"
  end

  test "reviewer deve pertencer à guilda" do
    request = MissionRequest.new(
      guild: guilds(:one),
      requester: users(:five),
      reviewer: users(:three),
      title: "Pedido com revisor inválido",
      description: "Revisor de outra guilda."
    )

    assert_not request.valid?
    assert_includes request.errors[:reviewer], "deve pertencer à guilda"
  end

  test "requester pode criar quando possui cargo especial" do
    requester = users(:five)
    role = Role.create!(
      guild: requester.guild,
      name: "Explorador Especial",
      category: "special"
    )
    requester.user_roles.create!(role: role)
    request = MissionRequest.new(
      guild: requester.guild,
      requester: requester,
      title: "Expedição especial",
      description: "Explorar uma rota rara."
    )

    assert request.requester_can_create?
  end

  test "requester pode criar quando tem permissão de missões" do
    request = MissionRequest.new(
      guild: users(:one).guild,
      requester: users(:one),
      title: "Missão administrativa",
      description: "Pedido feito por gestor."
    )

    assert request.requester_can_create?
  end

  test "requester comum não pode criar pedido especial" do
    request = MissionRequest.new(
      guild: users(:five).guild,
      requester: users(:five),
      title: "Pedido comum",
      description: "Sem cargo especial."
    )

    assert_not request.requester_can_create?
  end

  test "aprova e audita requisição" do
    request = MissionRequest.create!(
      guild: guilds(:one),
      requester: users(:five),
      title: "Missão de coleta",
      description: "Coletar ervas."
    )

    assert_difference -> { AuditLog.where(action: "mission_request_approved").count }, 1 do
      request.approve!(reviewer: users(:one), notes: "aprovado")
    end

    assert_equal "approved", request.status
    assert_equal users(:one), request.reviewer
    assert_equal "aprovado", request.admin_notes
  end
end
