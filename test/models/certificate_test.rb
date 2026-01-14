require "test_helper"

class CertificateTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    certificate = Certificate.new(
      guild: guilds(:one),
      code: "test_cert",
      name: "Test Certificate"
    )
    assert certificate.valid?
  end

  test "deve exigir code" do
    certificate = Certificate.new(
      guild: guilds(:one),
      name: "Test"
    )
    assert_not certificate.valid?
    assert_includes certificate.errors[:code], "can't be blank"
  end

  test "deve exigir name" do
    certificate = Certificate.new(
      guild: guilds(:one),
      code: "test"
    )
    assert_not certificate.valid?
    assert_includes certificate.errors[:name], "can't be blank"
  end

  # === Relacionamentos ===

  test "deve pertencer a uma guilda" do
    certificate = certificates(:one)
    assert_respond_to certificate, :guild
    assert_instance_of Guild, certificate.guild
  end

  test "deve ter muitos user_certificates" do
    certificate = certificates(:one)
    assert_respond_to certificate, :user_certificates
  end

  test "deve ter muitos usuários através de user_certificates" do
    certificate = certificates(:one)
    assert_respond_to certificate, :users
  end

  test "deve ter muitos role_certificate_requirements" do
    certificate = certificates(:one)
    assert_respond_to certificate, :role_certificate_requirements
  end

  test "deve ter muitos roles através de role_certificate_requirements" do
    certificate = certificates(:one)
    assert_respond_to certificate, :roles
  end

  test "deve destruir user_certificates ao ser destruído" do
    certificate = certificates(:two)
    UserCertificate.create!(user: users(:three), certificate: certificate, status: "granted")
    user_cert_count = certificate.user_certificates.count
    assert user_cert_count > 0

    assert_difference("UserCertificate.count", -user_cert_count) do
      certificate.destroy
    end
  end

  test "deve destruir role_certificate_requirements ao ser destruído" do
    certificate = certificates(:two)
    RoleCertificateRequirement.create!(role: roles(:two), certificate: certificate)
    req_count = certificate.role_certificate_requirements.count
    assert req_count > 0

    assert_difference("RoleCertificateRequirement.count", -req_count) do
      certificate.destroy
    end
  end
end
