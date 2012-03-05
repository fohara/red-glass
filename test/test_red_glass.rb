require_relative '../lib/red-glass/red_glass'
require "test/unit"
require "selenium-webdriver"
require "json"

class TestRedGlass < Test::Unit::TestCase
  PROJ_ROOT = File.dirname(__FILE__).to_s

  def test_events_captured_in_browser_and_sent_to_red_glass_app_server

=begin
    #TODO Get htmlunit browser working. This would allow tests to run without launching a gui browser.
    #Error raised: 'Selenium::WebDriver::Error::UnknownError: Error forwarding the new session Empty pool of VM for setup'
    pid = start_selenium_server
    caps = Selenium::WebDriver::Remote::Capabilities.htmlunit(:javascript_enabled => true)
    driver = Selenium::WebDriver.for :remote, :url => "http://localhost:4444/wd/hub", :desired_capabilities => caps
=end

    driver = Selenium::WebDriver.for :firefox
    red_glass = RedGlass.new driver

    driver.get "http://google.com"
    red_glass.start

    driver.find_element(:name, 'q').send_keys 'a'
    driver.quit
    uri = URI.parse("http://localhost:4567/events")
    event = JSON.parse(Net::HTTP.get_response(uri).body.to_s)[0]
    ['url', 'testID', 'time', 'type', 'target'].each do |property|
      assert !event[property].nil?
    end
    red_glass.stop

    #stop_selenium_server pid
  end

=begin
  #htmlunit / selenium server helper methods.
  def is_server_ready?(time_limit=30)
    is_server_ready = false
    uri = URI.parse("http://localhost:4444")
    counter = 0
    loop do
      sleep(1)
      counter = counter + 1
      begin
        is_server_ready = Net::HTTP.get_response(uri).code.to_s == '200' ? true : false
      rescue
        is_server_ready = false
      end
      break if is_server_ready || counter >= time_limit
    end
    is_server_ready
  end

  def start_selenium_server
    pid = nil
    if !is_server_ready? 1
      #TODO Add the selenium server jar to the test directory.
      pid = Process.spawn("java", "-jar","#{PROJ_ROOT}/selenium-server-standalone-2.20.0.jar", "-role", "hub")
      raise "Selenium server could not be started." if !is_server_ready?
      Process.detach pid
    end
    pid
  end

  def stop_selenium_server(pid)
    Process.kill('INT', pid)
  end
=end

end