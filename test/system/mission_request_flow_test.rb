require "application_system_test_case"

class MissionRequestFlowTest < ApplicationSystemTestCase
  setup do
    # users(:one) tem cargo máximo, logo possui manage_missions e pode requisitar missões.
    @requester = users(:one)
  end

  test "privileged member requests a custom mission from the mission board" do
    system_sign_in(@requester, visit_after_sign_in: missions_path)

    click_link "Requisitar missão"
    assert_text "Requisitar missão"

    fill_in "Título", with: "Caçada ao chefe mundial"
    fill_in "Descrição", with: "Sugiro uma missão de caçada coordenada ao chefe mundial neste fim de semana."

    assert_difference -> { MissionRequest.count }, 1 do
      click_button "Enviar requisição"
      assert_text "Requisição de missão enviada para a administração"
    end

    request = MissionRequest.order(:created_at).last
    assert_equal "Caçada ao chefe mundial", request.title
    assert_equal @requester, request.requester
    assert_equal @requester.guild, request.guild
  end
end
