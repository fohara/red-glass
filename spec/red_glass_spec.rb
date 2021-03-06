require 'spec_helper'
require_relative '../lib/red-glass/red_glass'
require_relative '../lib/red-glass/red_glass_listener'

describe RedGlass do

  it 'captures browser events and sends them to the RedGlass app server' do
    driver = Selenium::WebDriver.for :firefox
    red_glass = RedGlass.new(driver, { server_log: true })
    driver.navigate.to 'http://google.com'
    red_glass.start
    driver.find_element(:name, 'q').send_keys 'a'

    uri = URI.parse('https://localhost:4567/events')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.get(uri.request_uri)
    event = JSON.parse(response.body.to_s)[0]

    %w(url testID time type target).each do |property|
      expect(event.has_key?(property)).to be_truthy
      expect(event[property]).to_not be_nil
    end
    driver.quit
    red_glass.stop
  end

  context 'having navigated to a new page' do
    it 'should reload the jQuery plugin' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      driver.navigate.to 'http://google.com'
      red_glass.start
      expect(red_glass).to receive(:reload).once
      driver.navigate.to 'http://news.google.com'
      driver.quit
      red_glass.stop
    end
    context 'using #get' do
      it 'should reload the jQuery plugin' do
        listener = RedGlassListener.new
        driver = Selenium::WebDriver.for :firefox, :listener => listener
        red_glass = RedGlass.new driver, {listener: listener}
        driver.get 'http://google.com'
        red_glass.start
        expect(red_glass).to receive(:reload).once
        driver.navigate.to 'http://news.google.com'
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
      driver.navigate.to 'http://google.com'
      red_glass.start
      expect(red_glass).to receive(:reload).twice
      driver.navigate.to 'http://news.google.com'
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
      driver.navigate.to 'http://google.com'
      red_glass.start
      expect(red_glass).to receive(:reload).exactly(3).times
      driver.navigate.to 'http://news.google.com'
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
      red_glass.start
      driver.navigate.to 'http://example.com'
      driver.find_element(:tag_name, 'h1').click
      expect(red_glass.event_sequence).to eq [{:click => 'h1'}]
      driver.quit
      red_glass.stop
    end
    it 'records two click events' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      red_glass.start
      driver.navigate.to 'http://example.com'
      2.times { driver.find_element(:tag_name, 'h1').click }
      expect(red_glass.event_sequence).to eq [{:click => 'h1'}, {:click => 'h1'}]
      driver.quit
      red_glass.stop
    end
    it 'records a value change event' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      red_glass.start
      driver.navigate.to 'http://google.com'
      driver.find_element(:name, 'q').send_keys 'a'
      expect(red_glass.event_sequence).to eq [{:change_value => 'input'}]
      driver.quit
      red_glass.stop
    end
    it 'records two value change events' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      red_glass = RedGlass.new driver, {listener: listener}
      red_glass.start
      driver.navigate.to 'http://google.com'
      2.times { driver.find_element(:name, 'q').send_keys 'a' }
      expect(red_glass.event_sequence).to eq [{:change_value => 'input'}, {:change_value => 'input'}]
      driver.quit
      red_glass.stop
    end
    context 'having navigated to a new page' do
      it 'clears the sequence' do
        listener = RedGlassListener.new
        driver = Selenium::WebDriver.for :firefox, :listener => listener
        red_glass = RedGlass.new driver, {listener: listener}
        red_glass.start
        driver.navigate.to 'http://google.com'
        driver.find_element(:id, 'hplogo').click
        driver.navigate.to 'http://news.google.com'
        expect(red_glass.event_sequence.empty?).to be_truthy
        driver.quit
        red_glass.stop
      end
    end
  end

  describe '#take_snapshot' do
    it 'creates an archive directory' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      dir = Dir.mktmpdir
      red_glass = RedGlass.new driver, {listener: listener, archive_location: dir, test_id: 1}
      driver.navigate.to 'http://google.com'
      red_glass.take_snapshot
      driver.quit
      red_glass.stop
      expect(File.directory?("#{dir}/1")).to be_truthy
      FileUtils.remove_entry dir
    end
    it 'serializes the DOM' do
      listener = RedGlassListener.new
      driver = Selenium::WebDriver.for :firefox, :listener => listener
      dir = Dir.mktmpdir
      red_glass = RedGlass.new driver, {listener: listener, archive_location: dir, test_id: 1}
      driver.navigate.to 'http://example.com'
      red_glass.take_snapshot
      driver.quit
      red_glass.stop

      expect(File.directory?("#{dir}/1")).to be_truthy
      archive_dir = `ls -d #{dir}/1/*/`
      dom = JSON.parse(File.open("#{archive_dir.chomp}dom.json", 'rb').read, { symbolize_names: true})
      expect(dom.has_key?(:browser)).to be_truthy
      expect(dom.has_key?(:elements)).to be_truthy
      html_node = dom[:elements].first
      expect(html_node[:tagName]).to eq 'HTML'
      expect(html_node[:top]).to eq 0
      expect(html_node[:left]).to eq 0
      expect(html_node[:xpath]).to eq '//html[1]'
      FileUtils.remove_entry dir
    end
    context 'with required RedGlass options' do
      before :each do
        @internal_methods = [:capture_page_metadata, :create_page_archive_directory, :take_screenshot, :capture_page_source, :load_js, :serialize_dom, :write_metadata]
        listener = RedGlassListener.new
        @driver = double('driver')
        @red_glass = RedGlass.new @driver, {listener: listener, archive_location: ''}
      end

      it 'captures page metadata' do
        @internal_methods.delete_if { |method| method == :capture_page_metadata}.each do |method|
          allow(@red_glass).to receive(method)
        end
        expect(@red_glass).to receive(:capture_page_metadata).once
        @red_glass.take_snapshot
      end
      it 'creates an archive location' do
        @internal_methods.delete_if { |method| method == :create_page_archive_directory}.each do |method|
          allow(@red_glass).to receive(method)
        end
        expect(@red_glass).to receive(:create_page_archive_directory).once
        @red_glass.take_snapshot
      end
      it 'takes a screenshot' do
        @internal_methods.delete_if { |method| method == :take_screenshot}.each do |method|
          allow(@red_glass).to receive(method)
        end
        expect(@red_glass).to receive(:take_screenshot).once
        @red_glass.take_snapshot
      end
      it 'captures page source' do
        @internal_methods.delete_if { |method| method == :capture_page_source}.each do |method|
          allow(@red_glass).to receive(method)
        end
        expect(@red_glass).to receive(:capture_page_source).once
        @red_glass.take_snapshot
      end
      it 'serializes the DOM' do
        @internal_methods.delete_if { |method| method == :serialize_dom}.each do |method|
          allow(@red_glass).to receive(method)
        end
        expect(@red_glass).to receive(:serialize_dom).once
        @red_glass.take_snapshot
      end
      it 'writes metadata' do
        @internal_methods.delete_if { |method| method == :write_metadata}.each do |method|
          allow(@red_glass).to receive(method)
        end
        expect(@red_glass).to receive(:write_metadata).once
        @red_glass.take_snapshot
      end
    end

    context 'without an archive location' do
      it 'raises an error' do
        listener = RedGlassListener.new
        driver = double('driver')
        red_glass = RedGlass.new driver, {listener: listener}
        allow(red_glass).to receive(:capture_page_metadata)
        expect { red_glass.take_snapshot }.to raise_error('You must specify a valid archive location by passing an :archive_location option into the RedGlass initializer.')
      end
    end

  end
end