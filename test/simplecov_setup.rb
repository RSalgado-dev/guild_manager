# frozen_string_literal: true

require "simplecov"

unless SimpleCov.running
  SimpleCov.root File.expand_path("..", __dir__)

  SimpleCov.start "rails" do
    command_name "rails-tests"
    enable_coverage :branch
    merge_timeout 3600

    add_filter "app/controllers/dev_sessions_controller.rb"

    add_group "Admin", "app/admin"
    add_group "Services", "app/services"
  end
end
