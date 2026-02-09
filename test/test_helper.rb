ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "ostruct"
require "mocha/minitest"

# Configura WebMock para permitir requisições locais
WebMock.disable_net_connect!(allow_localhost: true)

# Configura OmniAuth para modo de teste
OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Limpa mocks do OmniAuth após cada teste
    teardown do
      OmniAuth.config.mock_auth[:discord] = nil
    end
  end
end
