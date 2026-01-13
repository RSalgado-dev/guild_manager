require "test_helper"

class EventParticipationTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    participation = EventParticipation.new(
      event: events(:one),
      user: users(:three),
      rsvp_status: "yes",
      attended: false
    )
    assert participation.valid?
  end

  test "não deve ser válido sem evento" do
    participation = EventParticipation.new(
      user: users(:one),
      rsvp_status: "yes"
    )
    assert_not participation.valid?
  end

  test "não deve ser válido sem usuário" do
    participation = EventParticipation.new(
      event: events(:one),
      rsvp_status: "yes"
    )
    assert_not participation.valid?
  end

  test "não deve permitir combinação duplicada de evento e usuário" do
    # event_participations(:one) já tem event:one e user:one
    participation = EventParticipation.new(
      event: events(:one),
      user: users(:one),
      rsvp_status: "yes"
    )
    assert_not participation.valid?
    assert_includes participation.errors[:event_id], "has already been taken"
  end

  test "deve permitir mesmo usuário em eventos diferentes" do
    participation = EventParticipation.new(
      event: events(:three),
      user: users(:one),
      rsvp_status: "yes"
    )
    assert participation.valid?
  end

  test "deve permitir mesmo evento para usuários diferentes" do
    participation = EventParticipation.new(
      event: events(:one),
      user: users(:three),
      rsvp_status: "yes"
    )
    assert participation.valid?
  end

  test "deve validar rsvp_status permitindo apenas valores válidos" do
    participation = event_participations(:one)

    assert_nothing_raised do
      participation.rsvp_status = "yes"
      participation.valid?

      participation.rsvp_status = "maybe"
      participation.valid?

      participation.rsvp_status = "no"
      participation.valid?

      participation.rsvp_status = nil
      participation.valid?
    end
  end

  test "não deve validar rsvp_status com valor inválido" do
    participation = EventParticipation.new(
      event: events(:one),
      user: users(:three),
      rsvp_status: "invalid"
    )
    assert_not participation.valid?
    assert_includes participation.errors[:rsvp_status], "is not included in the list"
  end

  # === Relacionamentos ===

  test "deve pertencer a um evento" do
    participation = event_participations(:one)
    assert_respond_to participation, :event
    assert_instance_of Event, participation.event
  end

  test "deve pertencer a um usuário" do
    participation = event_participations(:one)
    assert_respond_to participation, :user
    assert_instance_of User, participation.user
  end

  # === Scopes ===

  test "scope attended deve retornar apenas participações com attended true" do
    attended = EventParticipation.attended
    assert attended.all? { |p| p.attended == true }
    assert attended.count > 0
  end

  test "scope attended não deve retornar participações com attended false" do
    attended = EventParticipation.attended
    not_attended = event_participations(:one) # tem attended: false
    assert_not attended.include?(not_attended)
  end

  # === Comportamento ===

  test "attended deve ser false por padrão" do
    participation = EventParticipation.new(
      event: events(:one),
      user: users(:three),
      rsvp_status: "yes"
    )
    assert_equal false, participation.attended
  end

  test "deve permitir definir attended como true" do
    participation = EventParticipation.new(
      event: events(:one),
      user: users(:three),
      rsvp_status: "yes",
      attended: true
    )
    assert participation.valid?
    assert_equal true, participation.attended
  end

  test "rewarded_at pode ser nil" do
    participation = event_participations(:one)
    assert_nil participation.rewarded_at
  end

  test "rewarded_at pode ter uma data" do
    participation = event_participations(:two)
    assert_not_nil participation.rewarded_at
    assert_instance_of ActiveSupport::TimeWithZone, participation.rewarded_at
  end
end
