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
