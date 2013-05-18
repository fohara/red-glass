require 'spec_helper'
require_relative '../lib/red-glass/red_glass'

describe 'RedGlass' do

  it 'captures browser events and sends them to the RedGlass app server' do
    driver = Selenium::WebDriver.for :firefox
    red_glass = RedGlass.new driver

    driver.navigate.to "http://google.com"
    red_glass.start

    driver.find_element(:name, 'q').send_keys 'a'
    driver.quit
    uri = URI.parse("http://localhost:4567/events")
    event = JSON.parse(Net::HTTP.get_response(uri).body.to_s)[0]
    %w(url testID time type target).each do |property|
      event[property].nil?.should be_false
    end
    red_glass.stop
  end
end