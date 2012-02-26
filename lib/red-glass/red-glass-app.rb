require 'sinatra/base'
require 'mongo_mapper'
require 'json'

MongoMapper.database = 'redglass'

class DomEvent
  include MongoMapper::Document

  #key :url
  key :test_id
  key :time
  key :type
  key :target
  key :method
  key :response
  key :error_message
  key :error_line_number

  timestamps!
end

class RedGlassApp < Sinatra::Base

  get '/' do
    erb :index
  end

  get '/events' do
    events = DomEvent.where(:test_id => {:$nin => params[:event_ids]}, :target => {:$ne => ""}).sort(:time.asc)
    events.to_json
  end

  post '/' do
    puts "#{params[:event_json]}\n"
    event = JSON.parse(params[:event_json])
    dom_event = DomEvent.new
    dom_event.test_id = event['testID']
    dom_event.time = event['time']
    dom_event.type = event['type']
    dom_event.target = event['target']
    dom_event.response = event['response'] if !event['response'].nil?
    dom_event.method = event['method'] if !event['method'].nil?
    dom_event.error_message = event['errorMessage'] if !event['errorMessage'].nil?
    dom_event.error_line_number = event['errorLineNumber'] if !event['errorLineNumber'].nil?
    dom_event.save
  end

  get '/status' do
    'ready'
  end

  get '/kill' do
    Process.kill('INT', 0)
  end

  red_glass_port = ENV['red_glass_port'].nil? ? 4567 : ENV['red_glass_port']

  RedGlassApp.run!({:port => red_glass_port})
end
