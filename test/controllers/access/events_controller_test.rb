require "test_helper"

class Access::EventsControllerTest < ActionDispatch::IntegrationTest
  test "gerente visualiza eventos vencidos ainda não finalizados na listagem" do
    sign_in(users(:one))

    overdue_event = Event.create!(
      guild: users(:one).guild,
      creator: users(:one),
      title: "Raid pendente de fechamento",
      event_type: "raid",
      starts_at: 2.hours.ago,
      ends_at: 1.hour.ago,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )

    get events_path

    assert_response :success
    assert_includes response.body, "Pendentes de finalização"
    assert_includes response.body, overdue_event.title
    assert_includes response.body, "Aguardando revisão"
    assert_includes response.body, "href=\"#{event_path(overdue_event)}\""
    assert_includes response.body, attendance_event_path(overdue_event)
    assert_includes response.body, review_event_path(overdue_event)
  end

  test "usuário com permissão pode criar evento" do
    sign_in(users(:one))

    assert_difference -> { AuditLog.where(action: "event_created").count }, 1 do
      assert_difference("Event.count", 1) do
        post events_path, params: {
          event: {
            title: "Cerco semanal",
            description: "Ataque coordenado",
            event_type: "siege",
            starts_at: 2.days.from_now,
            ends_at: 2.days.from_now + 2.hours,
            recurrence: "weekly",
            reward_xp: 180,
            reward_currency: 90
          }
        }
      end
    end

    event = Event.order(:created_at).last
    assert_redirected_to event_path(event)
    assert_equal users(:one), event.creator
    assert_equal "weekly", event.recurrence
    assert_equal users(:one).guild.users.count, event.event_participations.count
  end

  test "criação mantém horário informado no timezone padrão da aplicação" do
    sign_in(users(:one))

    post events_path, params: {
      event: {
        title: "Evento horario brasilia",
        description: "Teste de timezone fixo",
        event_type: "raid",
        starts_at: "2026-04-01T20:00",
        ends_at: "2026-04-01T22:00",
        recurrence: "unique",
        reward_xp: 100,
        reward_currency: 50
      }
    }

    event = Event.order(:created_at).last
    assert_redirected_to event_path(event)
    assert_equal "2026-04-01 20:00", event.starts_at.in_time_zone("Brasilia").strftime("%Y-%m-%d %H:%M")
    assert_equal "2026-04-01 22:00", event.ends_at.in_time_zone("Brasilia").strftime("%Y-%m-%d %H:%M")
  end

  test "usuário pode responder presença dentro do prazo" do
    sign_in(users(:two))

    event = Event.create!(
      guild: users(:two).guild,
      creator: users(:one),
      title: "Evento futuro",
      event_type: "raid",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 1.hour,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )

    assert_difference -> { AuditLog.where(action: "event_rsvp_updated").count }, 1 do
      patch respond_event_path(event), params: {
        event_participation: {
          rsvp_status: "declined",
          justification: "Viagem"
        }
      }
    end

    assert_redirected_to event_path(event)
    participation = event.event_participations.find_by!(user: users(:two))
    assert_equal "declined", participation.rsvp_status
    assert_equal "Viagem", participation.justification
    assert_not_nil participation.responded_at
  end

  test "usuário precisa justificar ausência ao recusar presença" do
    user = users(:two)
    sign_in(user)

    event = Event.create!(
      guild: user.guild,
      creator: users(:one),
      title: "Evento com justificativa obrigatória",
      event_type: "raid",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 1.hour,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )

    assert_no_difference -> { AuditLog.where(action: "event_rsvp_updated").count } do
      patch respond_event_path(event), params: {
        event_participation: {
          rsvp_status: "declined",
          justification: ""
        }
      }
    end

    assert_redirected_to event_path(event)
    participation = event.event_participations.find_by!(user: user)
    assert_not_equal "declined", participation.rsvp_status
  end

  test "usuário não pode responder presença após o prazo de 15 minutos" do
    sign_in(users(:two))

    event = Event.create!(
      guild: users(:two).guild,
      creator: users(:one),
      title: "Evento quase iniciando",
      event_type: "raid",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )

    travel_to(event.starts_at - 14.minutes) do
      patch respond_event_path(event), params: {
        event_participation: {
          rsvp_status: "confirmed"
        }
      }
    end

    assert_redirected_to event_path(event)
    assert_equal "❌ O prazo para responder presença terminou.", flash[:alert]
    assert_equal "pending", event.event_participations.find_by!(user: users(:two)).reload.rsvp_status
  end

  test "gestor acompanha respostas de evento fechado sem depender da revisão" do
    manager = users(:one)
    sign_in(manager)

    event = Event.create!(
      guild: manager.guild,
      creator: manager,
      title: "Raid fechada sem revisão",
      event_type: "raid",
      starts_at: 1.day.ago,
      ends_at: 1.day.ago + 2.hours,
      recurrence: "unique",
      status: "completed",
      reward_xp: 100,
      reward_currency: 50
    )

    event.event_participations.find_by!(user: users(:one)).update!(rsvp_status: :confirmed, responded_at: 2.days.ago)
    event.event_participations.find_by!(user: users(:two)).update!(
      rsvp_status: :declined,
      justification: "Plantão no trabalho",
      responded_at: 2.days.ago
    )
    event.event_participations.find_by!(user: users(:four)).update!(rsvp_status: :pending, justification: nil)

    get attendance_event_path(event)

    assert_response :success
    assert_includes response.body, "Acompanhamento de presença"
    assert_includes response.body, "Finalizado"
    assert_includes response.body, users(:one).display_name_with_squad_tag
    assert_includes response.body, "Plantão no trabalho"
    assert_includes response.body, users(:four).display_name_with_squad_tag
  end

  test "gestor revisa presença em listagem compacta" do
    manager = users(:one)
    sign_in(manager)

    event = Event.create!(
      guild: manager.guild,
      creator: manager,
      title: "Raid para revisão compacta",
      event_type: "raid",
      starts_at: 1.day.ago,
      ends_at: 1.day.ago + 2.hours,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 50
    )

    confirmed = event.event_participations.find_by!(user: users(:one))
    justified = event.event_participations.find_by!(user: users(:two))

    confirmed.update!(rsvp_status: :confirmed, responded_at: 2.days.ago)
    justified.update!(
      rsvp_status: :declined,
      justification: "Plantão no trabalho",
      responded_at: 2.days.ago
    )

    get review_event_path(event)

    assert_response :success
    assert_includes response.body, "Revisão de presença"
    assert_includes response.body, "Aguardando revisão"
    assert_includes response.body, attendance_event_path(event)
    assert_includes response.body, "name=\"results[#{confirmed.id}]\""
    assert_includes response.body, "data-reward-preview-select"
    assert_includes response.body, "Recebe: 100 XP"
    assert_includes response.body, "data-reward-text=\"0 XP"
    assert_includes response.body, "Plantão no trabalho"
    assert_includes response.body, "Ausente"
    assert_includes response.body, "Finalizar evento e distribuir recompensas"
  end

  test "usuário sem permissão não acessa acompanhamento de presença" do
    user = users(:five)
    guild = user.guild
    role = guild.roles.create!(
      name: "Participante sem gestão",
      description: "Cargo sem permissões administrativas",
      category: "base",
      discord_role_id: "555555555555555555"
    )

    user.user_roles.destroy_all
    guild.update!(
      required_discord_role_id: role.discord_role_id,
      required_discord_role_name: role.name
    )

    sign_in(user)

    get attendance_event_path(events(:one))

    assert_redirected_to events_path
    assert_equal "❌ Você não tem permissão para gerenciar eventos.", flash[:alert]
  end

  test "fechamento do evento distribui recompensa conforme bloco e resultado" do
    sign_in(users(:one))

    event = Event.create!(
      guild: users(:one).guild,
      creator: users(:one),
      title: "Evento concluído",
      event_type: "raid",
      starts_at: 1.day.ago,
      ends_at: 1.day.ago + 2.hours,
      recurrence: "unique",
      reward_xp: 100,
      reward_currency: 100
    )

    confirmed = event.event_participations.find_by!(user: users(:one))
    justified = event.event_participations.find_by!(user: users(:two))
    unanswered = event.event_participations.find_by!(user: users(:four))

    confirmed.update!(rsvp_status: :confirmed)
    justified.update!(rsvp_status: :declined, justification: "Compromisso")
    unanswered.update!(rsvp_status: :pending, justification: nil)

    original_xp = {
      one: users(:one).xp_points,
      two: users(:two).xp_points,
      four: users(:four).xp_points
    }

    assert_difference -> { AuditLog.where(action: "event_completed").count }, 1 do
      assert_difference -> { AuditLog.where(action: "event_reward_awarded").count }, event.event_participations.count do
        patch complete_event_path(event), params: {
          results: {
            confirmed.id => "participated",
            justified.id => "justified",
            unanswered.id => "participated"
          }
        }
      end
    end

    assert_redirected_to event_path(event)
    assert_equal "completed", event.reload.status

    assert_equal 100, confirmed.reload.reward_xp_awarded
    assert_equal 20, justified.reload.reward_xp_awarded
    assert_equal 25, unanswered.reload.reward_xp_awarded

    assert_equal original_xp[:one] + 100, users(:one).reload.xp_points
    assert_equal original_xp[:two] + 20, users(:two).reload.xp_points
    assert_equal original_xp[:four] + 25, users(:four).reload.xp_points

    xp_after_completion = users(:one).reload.xp_points
    currency_transactions_after_completion = CurrencyTransaction.count

    assert_no_difference -> { AuditLog.where(action: "event_reward_awarded").count } do
      assert_no_difference -> { CurrencyTransaction.count } do
        patch complete_event_path(event), params: {
          results: {
            confirmed.id => "participated"
          }
        }
      end
    end

    assert_redirected_to event_path(event)
    assert_equal "❌ O evento já foi finalizado.", flash[:alert]
    assert_equal xp_after_completion, users(:one).reload.xp_points
    assert_equal currency_transactions_after_completion, CurrencyTransaction.count
  end
end
