require_relative '../lib/red-glass/red-glass-app'
require 'test/unit'
require 'rack/test'

class TestRedGlassApp < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    RedGlassApp.new
  end

  def test_status
    get '/status'
    assert_equal 'ready', last_response.body
  end

end