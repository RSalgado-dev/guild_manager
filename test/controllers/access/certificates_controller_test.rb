require "test_helper"

class Access::CertificatesControllerTest < ActionDispatch::IntegrationTest
  test "lista certificados ativos" do
    sign_in(users(:two))

    get certificates_path

    assert_response :success
    assert_includes response.body, certificates(:one).name
    assert_not_includes response.body, certificates(:inactive).name
  end

  test "exibe detalhe do certificado" do
    sign_in(users(:two))

    get certificate_path(certificates(:one))

    assert_response :success
    assert_includes response.body, certificates(:one).name
  end
end
