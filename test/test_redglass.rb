#ENV['RACK_ENV'] = 'test'
require_relative '../lib/red-glass/red-glass-app'
require 'test/unit'
require 'rack/test'
require 'thin'

class TestRedGlass < Test::Unit::TestCase
  include Rack::Test::Methods
  
  #set :environment, :test
  
  def app
    RedGlassApp.new
  end

  def setup
    puts 'setting up test'
    #@driver = Selenium::WebDriver.for :firefox
    #@red_glass = RedGlass.new @driver
  end

  def teardown
    get '/kill'
    #RedGlassApp.kill
    puts 'sent kill request'
  end

  def test_status
    get '/status'
    assert_equal 'ready', last_response.body
    puts 'ran test'   
  end

end
