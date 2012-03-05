require_relative '../lib/red-glass/red-glass-app'
require 'test/unit'
require 'rack/test'
require 'json'

class TestRedGlassApp < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @event_json = {"id"=>"", "url"=>"/", "testID"=>"ef100740-4860-012f-0d6d-00254bac7e96", "time"=>1330890507501, "type"=>"click", "pageX"=>592, "pageY"=>516, "target"=>"html > body > div#main > div#inner.gainlayout > div.form_controls > a"}
  end
  
  def app
    RedGlassApp.new
  end

  def test_status
    get '/status'
    assert_equal 'ready', last_response.body
  end

  def test_post_event
    post '/', "event_json" => @event_json.to_json
    assert last_response.ok?
  end

  def test_get_empty_events
    get '/events'
    assert_equal '[]', last_response.body
  end

  def test_get_single_event
    post '/', "event_json" => @event_json.to_json
    get '/events'
    assert_equal @event_json['url'], JSON.parse(last_response.body)[0]['url']
    assert_equal @event_json['testID'], JSON.parse(last_response.body)[0]['testID']
    assert_equal @event_json['time'], JSON.parse(last_response.body)[0]['time']
    assert_equal @event_json['type'], JSON.parse(last_response.body)[0]['type']
    assert_equal @event_json['target'], JSON.parse(last_response.body)[0]['target']
  end

  def test_get_multiple_events
    2.times do
      post '/', "event_json" => @event_json.to_json
    end
    get '/events'
    assert_equal 2, JSON.parse(last_response.body).size
  end

end