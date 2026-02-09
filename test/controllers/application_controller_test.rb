require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # Teste helpers através de controllers reais (SessionsController e AccessController)
  # Os métodos do ApplicationController são testados indiretamente através de testes
  # de integração nos testes de SessionsController e AccessController

  test "deve ter os helper methods definidos" do
    # Este teste garante que o ApplicationController está configurado corretamente
    # Os métodos current_user, logged_in?, has_guild_access? são helpers privados
    assert ApplicationController.private_method_defined?(:current_user) || ApplicationController.method_defined?(:current_user)
    assert ApplicationController.private_method_defined?(:logged_in?) || ApplicationController.method_defined?(:logged_in?)
    assert ApplicationController.private_method_defined?(:has_guild_access?) || ApplicationController.method_defined?(:has_guild_access?)
    assert ApplicationController.private_method_defined?(:require_login) || ApplicationController.method_defined?(:require_login)
    assert ApplicationController.private_method_defined?(:require_guild_access) || ApplicationController.method_defined?(:require_guild_access)
    assert ApplicationController.private_method_defined?(:require_admin) || ApplicationController.method_defined?(:require_admin)
  end
end
