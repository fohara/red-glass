require 'sinatra/base'
require 'thin'
require 'em-websocket'
require 'uuid'
require 'json'

class RedGlassApp < Sinatra::Base

  red_glass_port = ENV['red_glass_port'].nil? ? 4567 : ENV['red_glass_port']
  socket = nil
  is_socket_connected = false
  events = Array.new

  get '/' do
    erb :index
  end

  post '/?' do
    request.body.rewind
    event = JSON.parse(request.body.read)['event_json']
    begin
      uuid = UUID.new
      event['id'] = uuid.generate
    rescue
      event['id'] = event['time']
    end
    events << event
    if is_socket_connected
      socket.send events.to_json
      events.clear
    end
  end

  get '/events' do
    events.to_json
  end

  get '/status' do
    'ready'
  end

  get '/kill' do
    Process.kill('INT', 0)
  end

  if app_file == $0
    EventMachine.run do
      RedGlassApp.run!({:port => red_glass_port})
      EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 4568) do |ws|
        socket = ws
        ws.onopen { is_socket_connected = true }
        ws.onmessage { |msg|
          if msg == 'all'
            ws.send events.to_json
            events.clear
          end
        }
        ws.onclose   { }
      end
    end
  end

end