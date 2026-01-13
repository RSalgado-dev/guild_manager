require "test_helper"

module SystemTestCase
  extend ActiveSupport::Concern

  included do
    include ActionDispatch::SystemTestCase
  end

  class_methods do
    def driver_for(browser)
      case browser
      when :headless_chrome
        driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
      when :headless_firefox
        driven_by :selenium, using: :headless_firefox, screen_size: [ 1400, 1400 ]
      else
        driven_by :selenium, using: browser, screen_size: [ 1400, 1400 ]
      end
    end
  end
end

class ApplicationSystemTestCase < ActiveSupport::TestCase
  include SystemTestCase
  driver_for :headless_chrome
end
