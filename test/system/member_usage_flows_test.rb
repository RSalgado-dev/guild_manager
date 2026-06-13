require "application_system_test_case"

class MemberUsageFlowsTest < ApplicationSystemTestCase
  setup do
    @member = users(:five)
    @member.update!(has_guild_access: true, squad: nil, currency_balance: 100)
  end

  test "member submits a manual mission from the mission board" do
    mission = missions(:one)

    system_sign_in(@member)

    click_link "Missões"
    assert_text "Missões disponíveis"

    click_link mission.name
    assert_text "Enviar submissão"

    fill_in "Quantidade", with: "2"
    fill_in "Notas", with: "Completei pelo fluxo de sistema"
    click_button "Enviar para revisão"

    assert_text "Submissão enviada para revisão"
    assert_text "Envio 1"
    assert_text "Quantidade 2"

    submission = MissionSubmission.where(mission: mission, user: @member).order(:created_at).last
    assert_equal "pending", submission.status
    assert_equal 2, submission.quantity
    assert_equal({ "notes" => "Completei pelo fluxo de sistema" }, submission.answers_json)
  end

  test "member responds to an upcoming event" do
    event = Event.create!(
      guild: @member.guild,
      creator: users(:one),
      title: "Raid de Fluxo do Membro",
      description: "Evento para validar RSVP pela interface",
      event_type: "raid",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 2.hours,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )

    system_sign_in(@member)

    click_link "Eventos"
    assert_text event.title

    click_link event.title
    assert_text "Sua resposta"

    choose "event_participation_rsvp_status_declined"
    fill_in "Justificativa", with: "Sem disponibilidade neste horário"
    click_button "Salvar resposta"

    assert_text "Sua resposta foi registrada"
    assert_text "Ausência avisada"

    participation = event.event_participations.find_by!(user: @member)
    assert_equal "declined", participation.rsvp_status
    assert_equal "Sem disponibilidade neste horário", participation.justification
    assert_not_nil participation.responded_at
  end

  test "member accepts a squad invitation from the squads area" do
    invitation = squad_invitations(:one_pending)

    system_sign_in(@member)

    click_link "Squads"
    assert_text "Convites Recebidos"
    assert_text invitation.squad.name

    click_button "Aceitar"

    assert_text "Convite aceito"
    assert_text invitation.squad.name

    assert_equal "accepted", invitation.reload.status
    assert_equal invitation.squad_id, @member.reload.squad_id
  end

  test "member confirms presence for an upcoming event" do
    event = Event.create!(
      guild: @member.guild,
      creator: users(:one),
      title: "Raid de Confirmação do Membro",
      description: "Evento para validar confirmação de presença pela interface",
      event_type: "raid",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 2.hours,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )

    system_sign_in(@member)

    click_link "Eventos"
    assert_text event.title

    click_link event.title
    assert_text "Sua resposta"

    choose "event_participation_rsvp_status_confirmed"
    click_button "Salvar resposta"

    assert_text "Sua resposta foi registrada"
    assert_text "Confirmado"

    participation = event.event_participations.find_by!(user: @member)
    assert_equal "confirmed", participation.rsvp_status
    assert_nil participation.justification
    assert_not_nil participation.responded_at
  end

  test "member cancels a pending store order and is refunded" do
    item = StoreItem.create!(guild: @member.guild, name: "Item Reembolsável", price: 25, stock_quantity: 5)

    system_sign_in(@member)

    click_link "Loja"
    assert_text "Loja da Guild"
    assert_text item.name

    click_button "Comprar por 25 moedas"
    assert_text "Meus pedidos"
    assert_text item.name
    assert_text "pending"
    assert_equal 75, @member.reload.currency_balance

    click_button "Cancelar"

    assert_text "Pedido cancelado e moedas reembolsadas"

    order = @member.store_orders.order(:created_at).last
    assert_equal "canceled", order.reload.status
    assert_equal 100, @member.reload.currency_balance
  end

  test "member registers a game character from the profile" do
    character_owner = users(:six)
    character_owner.update!(has_guild_access: true)

    system_sign_in(character_owner)

    visit profile_path
    assert_text "Personagem do Jogo"

    click_link "Cadastrar Personagem"
    fill_in "Nickname", with: "FluxHero"
    fill_in "Nível", with: "42"
    fill_in "Poder", with: "12345"
    attach_file "Print da Tela de Status", Rails.root.join("test/fixtures/files/squad_emblem.png")
    check "Definir como personagem principal"
    click_button "Cadastrar Personagem"

    assert_text "Personagem cadastrado com sucesso"
    assert_text "FluxHero"

    character = character_owner.reload.game_characters.find_by!(nickname: "FluxHero")
    assert_equal 42, character.level
    assert_equal 12_345, character.power
    assert character.is_primary?
    assert character.status_screenshot.attached?
  end
end
