require_relative '../lib/red-glass/red_glass'
require "test/unit"
require "selenium-webdriver"
require "json"

class TestRedGlass < Test::Unit::TestCase
  PROJ_ROOT = File.dirname(__FILE__).to_s

  def test_events_captured_in_browser_and_sent_to_red_glass_app_server
    driver = Selenium::WebDriver.for :firefox
    red_glass = RedGlass.new driver

    driver.navigate.to "http://google.com"
    red_glass.start

    driver.find_element(:name, 'q').send_keys 'a'
    driver.quit
    uri = URI.parse("http://localhost:4567/events")
    event = JSON.parse(Net::HTTP.get_response(uri).body.to_s)[0]
    ['url', 'testID', 'time', 'type', 'target'].each do |property|
      assert !event[property].nil?
    end
    red_glass.stop
  end

end