require "test_helper"

Capybara.register_driver :headless_chrome_container do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_chrome_container, screen_size: [ 1400, 1400 ]
end
