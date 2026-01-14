require "test_helper"

class RoleCertificateRequirementTest < ActiveSupport::TestCase
  # === Validações ===

  test "deve ser válido com atributos válidos" do
    requirement = RoleCertificateRequirement.new(
      role: roles(:two),
      certificate: certificates(:one)
    )
    assert requirement.valid?
  end

  test "deve exigir role" do
    requirement = RoleCertificateRequirement.new(certificate: certificates(:one))
    assert_not requirement.valid?
    assert_includes requirement.errors[:role], "must exist"
  end

  test "deve exigir certificate" do
    requirement = RoleCertificateRequirement.new(role: roles(:one))
    assert_not requirement.valid?
    assert_includes requirement.errors[:certificate], "must exist"
  end

  test "deve ser único por role_id e certificate_id" do
    existing = role_certificate_requirements(:one)
    duplicate = RoleCertificateRequirement.new(
      role: existing.role,
      certificate: existing.certificate
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:role_id], "has already been taken"
  end

  test "mesmo role pode ter múltiplos certificados diferentes" do
    role = roles(:one)
    req1 = role_certificate_requirements(:one)
    req2 = role_certificate_requirements(:two)

    assert_equal role, req1.role
    assert_equal role, req2.role
    assert_not_equal req1.certificate, req2.certificate
  end

  # === Relacionamentos ===

  test "deve pertencer a um role" do
    requirement = role_certificate_requirements(:one)
    assert_respond_to requirement, :role
    assert_instance_of Role, requirement.role
  end

  test "deve pertencer a um certificate" do
    requirement = role_certificate_requirements(:one)
    assert_respond_to requirement, :certificate
    assert_instance_of Certificate, requirement.certificate
  end
end
