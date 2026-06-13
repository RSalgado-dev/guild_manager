require "application_system_test_case"

class EventManagementFlowsTest < ApplicationSystemTestCase
  setup do
    # users(:two) possui as permissões manage_events e manage_members via role two.
    @manager = users(:two)
  end

  test "manager creates an event through the form" do
    system_sign_in(@manager, visit_after_sign_in: events_path)

    click_link "Novo Evento"
    assert_text "Novo Evento"

    fill_in "Título", with: "Cerco de Teste E2E"
    fill_in "Tipo do evento", with: "siege"
    fill_in "Recompensa de XP", with: "120"
    fill_in "Recompensa de moedas", with: "60"
    fill_in "Descrição", with: "Evento criado pelo fluxo de sistema do gerente."

    click_button "Criar evento"

    assert_text "Evento criado com sucesso"
    assert_text "Cerco de Teste E2E"

    event = Event.order(:created_at).last
    assert_equal "Cerco de Teste E2E", event.title
    assert_equal @manager, event.creator
    assert_equal 120, event.reward_xp
    assert_equal 60, event.reward_currency
    # O evento deve gerar participações para os membros da guild.
    assert_equal @manager.guild.users.count, event.event_participations.count
  end

  test "manager reviews an overdue event and distributes rewards" do
    rewarded_member = users(:four)
    original_xp = rewarded_member.xp_points
    original_currency = rewarded_member.currency_balance

    event = Event.create!(
      guild: @manager.guild,
      creator: users(:one),
      title: "Raid Pendente de Fechamento",
      description: "Evento vencido aguardando revisão",
      event_type: "raid",
      starts_at: 2.hours.ago,
      ends_at: 1.hour.ago,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )
    event.event_participations.find_by!(user: rewarded_member).update!(rsvp_status: :confirmed)

    system_sign_in(@manager, visit_after_sign_in: events_path)

    assert_text "Pendentes de finalização"
    click_link event.title

    assert_text "Fechamento de #{event.title}"
    assert_text rewarded_member.display_name_with_squad_tag

    click_button "Finalizar evento e distribuir recompensas"

    assert_text "Evento finalizado e recompensas distribuídas"

    assert_equal "completed", event.reload.status

    participation = event.event_participations.find_by!(user: rewarded_member)
    assert_equal 100, participation.reward_xp_awarded
    assert_equal 50, participation.reward_currency_awarded
    assert_equal original_xp + 100, rewarded_member.reload.xp_points
    assert_equal original_currency + 50, rewarded_member.reload.currency_balance
  end
end
