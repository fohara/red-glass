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

  describe 'event sequence' do
    it 'records a click event' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to "http://google.com"
      driver.find_element(:id, 'hplogo').click
      red_glass.event_sequence.should eq [{:click => 'img'}]
      driver.quit
      red_glass.stop
    end
    it 'records two click events' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to "http://google.com"
      2.times { driver.find_element(:id, 'hplogo').click }
      red_glass.event_sequence.should eq [{:click => 'img'}, {:click => 'img'}]
      driver.quit
      red_glass.stop
    end
    it 'records a value change event' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to "http://google.com"
      driver.find_element(:name, 'q').send_keys 'a'
      red_glass.event_sequence.should eq [{:change_value => 'input'}]
      driver.quit
      red_glass.stop
    end
    it 'records two value change events' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to "http://google.com"
      2.times { driver.find_element(:name, 'q').send_keys 'a' }
      red_glass.event_sequence.should eq [{:change_value => 'input'}, {:change_value => 'input'}]
      driver.quit
      red_glass.stop
    end
    context 'having navigated to a new page' do
      it 'clears the sequence' do
        listener = RedGlassListener.new
        driver = Selenium::WebDriver.for :firefox, :listener => listener
        red_glass = RedGlass.new driver, {listener: listener}
        driver.navigate.to "http://google.com"
        driver.find_element(:id, 'hplogo').click
        driver.navigate.to "http://news.google.com"
        red_glass.event_sequence.empty?.should be_true
        driver.quit
        red_glass.stop
      end
    end
  end

  describe '#take_snapshot' do
    context 'with required RedGlass options' do
      before :each do
        @internal_methods = [:capture_page_metadata, :create_page_archive_directory, :take_screenshot, :capture_page_source, :write_metadata]
        listener = RedGlassListener.new
        @driver = double('driver')
        @red_glass = RedGlass.new @driver, {listener: listener, archive_location: ''}
      end

      it 'captures page metadata' do
        @internal_methods.delete_if { |method| method == :capture_page_metadata}.each do |method|
          @red_glass.stub(method)
        end
        @red_glass.should_receive(:capture_page_metadata).once
        @red_glass.take_snapshot
      end
      it 'creates an archive location' do
        @internal_methods.delete_if { |method| method == :create_page_archive_directory}.each do |method|
          @red_glass.stub(method)
        end
        @red_glass.should_receive(:create_page_archive_directory).once
        @red_glass.take_snapshot
      end
      it 'takes a screenshot' do
        @internal_methods.delete_if { |method| method == :take_screenshot}.each do |method|
          @red_glass.stub(method)
        end
        @red_glass.should_receive(:take_screenshot).once
        @red_glass.take_snapshot
      end
      it 'captures page source' do
        @internal_methods.delete_if { |method| method == :capture_page_source}.each do |method|
          @red_glass.stub(method)
        end
        @red_glass.should_receive(:capture_page_source).once
        @red_glass.take_snapshot
      end
      it 'writes metadata' do
        @internal_methods.delete_if { |method| method == :write_metadata}.each do |method|
          @red_glass.stub(method)
        end
        @red_glass.should_receive(:write_metadata).once
        @red_glass.take_snapshot
      end
    end

    context 'without an archive location' do
      it 'raises an error' do
        listener = RedGlassListener.new
        driver = double('driver')
        red_glass = RedGlass.new driver, {listener: listener}
        red_glass.stub(:capture_page_metadata)
        expect { red_glass.take_snapshot }.to raise_error('You must specify a valid archive location by passing an :archive_location option into the RedGlass initializer.')
      end
    end
  end
end