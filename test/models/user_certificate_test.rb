require "test_helper"

class UserCertificateTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    user_cert = UserCertificate.new(
      user: users(:two),
      certificate: certificates(:two),
      status: "granted"
    )
    assert user_cert.valid?
  end

  test "deve exigir user" do
    user_cert = UserCertificate.new(certificate: certificates(:one))
    assert_not user_cert.valid?
    assert_includes user_cert.errors[:user], "must exist"
  end

  test "deve exigir certificate" do
    user_cert = UserCertificate.new(user: users(:one))
    assert_not user_cert.valid?
    assert_includes user_cert.errors[:certificate], "must exist"
  end

  test "deve ser único por user_id e certificate_id" do
    existing = user_certificates(:one)
    duplicate = UserCertificate.new(
      user: existing.user,
      certificate: existing.certificate,
      status: "granted"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "mesmo usuário pode ter múltiplos certificados diferentes" do
    user = users(:one)
    cert1 = user_certificates(:one)
    cert2 = user_certificates(:two)

    assert_equal user, cert1.user
    assert_equal user, cert2.user
    assert_not_equal cert1.certificate, cert2.certificate
  end

  # === Relacionamentos ===

  test "deve pertencer a um usuário" do
    user_cert = user_certificates(:one)
    assert_respond_to user_cert, :user
    assert_instance_of User, user_cert.user
  end

  test "deve pertencer a um certificado" do
    user_cert = user_certificates(:one)
    assert_respond_to user_cert, :certificate
    assert_instance_of Certificate, user_cert.certificate
  end

  test "deve pertencer opcionalmente a granted_by" do
    user_cert = user_certificates(:one)
    assert_respond_to user_cert, :granted_by
    if user_cert.granted_by.present?
      assert_instance_of User, user_cert.granted_by
    end
  end

  # === Enums ===

  test "deve ter status granted" do
    user_cert = user_certificates(:one)
    assert_equal "granted", user_cert.status
  end

  test "deve ter status revoked" do
    user_cert = user_certificates(:revoked)
    assert_equal "revoked", user_cert.status
  end

  # === Callbacks ===

  test "deve definir granted_at automaticamente ao criar" do
    user_cert = UserCertificate.new(
      user: users(:three),
      certificate: certificates(:two),
      status: "granted"
    )
    assert_nil user_cert.granted_at

    user_cert.save!
    assert_not_nil user_cert.granted_at
    assert_in_delta Time.current, user_cert.granted_at, 2.seconds
  end

  test "não deve sobrescrever granted_at se já estiver definido" do
    custom_time = 10.days.ago
    user_cert = UserCertificate.new(
      user: users(:three),
      certificate: certificates(:two),
      granted_at: custom_time,
      status: "granted"
    )
    user_cert.save!
    assert_equal custom_time.to_i, user_cert.granted_at.to_i
  end

  # === Métodos ===

  test "#expired? deve retornar true quando expirado" do
    user_cert = user_certificates(:three)
    assert user_cert.expired?, "Certificado deveria estar expirado"
  end

  test "#expired? deve retornar false quando não expirado" do
    user_cert = user_certificates(:one)
    assert_not user_cert.expired?, "Certificado não deveria estar expirado"
  end

  test "#expired? deve retornar false quando expires_at é nil" do
    user_cert = user_certificates(:two)
    assert_not user_cert.expired?, "Certificado sem expiração não deveria estar expirado"
  end
end
