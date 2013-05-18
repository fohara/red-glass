require 'spec_helper'
require_relative '../lib/red-glass/red_glass'
require_relative '../lib/red-glass/red_glass_listener'

describe RedGlass do

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

  context 'having navigated to a new page' do
    it 'should reload the jQuery plugin' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to "http://google.com"
      red_glass.start
      red_glass.should_receive(:reload).once
      driver.navigate.to "http://news.google.com"
      driver.quit
      red_glass.stop
    end
    context 'using #get' do
      it 'should reload the jQuery plugin' do
        listener = RedGlassListener.new
        driver = Selenium::WebDriver.for :firefox, :listener => listener
        red_glass = RedGlass.new driver, {listener: listener}
        driver.get "http://google.com"
        red_glass.start
        red_glass.should_receive(:reload).once
        driver.navigate.to "http://news.google.com"
        driver.quit
        red_glass.stop
      end
    end
  end

  context 'having navigated back to a page' do
    it 'should reload the jQuery plugin twice' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to "http://google.com"
      red_glass.start
      red_glass.should_receive(:reload).twice
      driver.navigate.to "http://news.google.com"
      driver.navigate.back
      driver.quit
      red_glass.stop
    end
  end

  context 'having navigated back to a page and then forward' do
    it 'should reload the jQuery plugin three times' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to "http://google.com"
      red_glass.start
      red_glass.should_receive(:reload).exactly(3).times
      driver.navigate.to "http://news.google.com"
      driver.navigate.back
      driver.navigate.forward
      driver.quit
      red_glass.stop
    end
  end
end