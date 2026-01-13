require "test_helper"

class EventTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      title: "Evento Teste",
      event_type: "raid",
      starts_at: 1.day.from_now,
      status: :scheduled
    )
    assert event.valid?
  end

  test "não deve ser válido sem título" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      event_type: "raid",
      starts_at: 1.day.from_now
    )
    assert_not event.valid?
    assert_includes event.errors[:title], "can't be blank"
  end

  test "não deve ser válido sem event_type" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      title: "Evento Teste",
      starts_at: 1.day.from_now
    )
    assert_not event.valid?
    assert_includes event.errors[:event_type], "can't be blank"
  end

  test "não deve ser válido sem starts_at" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      title: "Evento Teste",
      event_type: "raid"
    )
    assert_not event.valid?
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "não deve ser válido sem guilda" do
    event = Event.new(
      creator: users(:one),
      title: "Evento Teste",
      event_type: "raid",
      starts_at: 1.day.from_now
    )
    assert_not event.valid?
  end

  test "não deve ser válido sem criador" do
    event = Event.new(
      guild: guilds(:one),
      title: "Evento Teste",
      event_type: "raid",
      starts_at: 1.day.from_now
    )
    assert_not event.valid?
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    event = events(:one)
    assert_respond_to event, :guild
    assert_instance_of Guild, event.guild
  end

  test "deve pertencer a um criador" do
    event = events(:one)
    assert_respond_to event, :creator
    assert_instance_of User, event.creator
  end

  test "deve ter muitos participantes" do
    event = events(:one)
    assert_respond_to event, :event_participations
  end

  test "deve ter muitos usuários através de participantes" do
    event = events(:one)
    assert_respond_to event, :users
  end

  test "deve destruir participações ao ser destruído" do
    event = events(:two)
    participation_count = event.event_participations.count
    assert_difference("EventParticipation.count", -participation_count) do
      event.destroy
    end
  end

  # === Enums ===

  test "deve aceitar status válidos" do
    event = events(:one)

    assert_nothing_raised do
      event.status = :scheduled
      event.status = :completed
      event.status = :canceled
    end
  end

  test "deve ter status scheduled por padrão" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      title: "Novo Evento",
      event_type: "raid",
      starts_at: 1.day.from_now
    )
    assert event.valid?
  end

  test "deve verificar diferentes status" do
    scheduled = events(:one)
    assert_equal "scheduled", scheduled.status

    completed = events(:two)
    assert_equal "completed", completed.status

    canceled = events(:three)
    assert_equal "canceled", canceled.status
  end

  # === Métodos ===

  test "#finished? deve retornar true quando o evento já terminou" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      title: "Evento Passado",
      event_type: "raid",
      starts_at: 2.days.ago,
      ends_at: 1.day.ago
    )
    assert event.finished?
  end

  test "#finished? deve retornar false quando o evento não terminou" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      title: "Evento Futuro",
      event_type: "raid",
      starts_at: 1.day.from_now,
      ends_at: 2.days.from_now
    )
    assert_not event.finished?
  end

  test "#finished? deve retornar false quando ends_at é nil" do
    event = Event.new(
      guild: guilds(:one),
      creator: users(:one),
      title: "Evento Sem Fim",
      event_type: "raid",
      starts_at: 1.day.ago,
      ends_at: nil
    )
    assert_not event.finished?
  end
end
