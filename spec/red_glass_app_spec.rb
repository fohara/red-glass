require 'spec_helper'
require_relative '../lib/red-glass/red-glass-app'

describe 'RedGlass App' do

  def app
    RedGlassApp
  end

  let(:event_json) { {"id"=>"", "url"=>"/", "testID"=>"ef100740-4860-012f-0d6d-00254bac7e96", "time"=>1330890507501,
                      "type"=>"click", "pageX"=>592, "pageY"=>516,
                      "target"=>"html > body > div#main > div#inner.gainlayout > div.form_controls > a"}}
  let(:event_keys) { %w(url testID time type target) }

  describe 'status' do
    describe 'GET' do
      it 'returns a ready message' do
        get '/status'
        last_response.body.should eq 'ready'
      end
    end
  end

  describe 'events' do
    describe 'GET' do
      context 'when no events are available' do
        it 'returns an empty array' do
          get '/events'
          last_response.body.should eq '[]'
        end
      end
    end

    describe 'POST' do
      it 'returns multiple events' do
        2.times do
          post '/', 'event_json' => event_json.to_json
        end
        get '/events'
        JSON.parse(last_response.body).size.should eq 2
      end
      it 'returns a success response code' do
        post '/', 'event_json' => event_json.to_json
        last_response.ok?.should be_true
      end
      it 'returns correctly structured JSON' do
        post '/', 'event_json' => event_json.to_json
        get '/events'
        event_keys.each do |key|
          JSON.parse(last_response.body).first[key].should eq event_json[key]
        end
      end
    end
  end
end