require 'sinatra/base'
require 'em-websocket'
require "uuid"
require 'json'

EventMachine.run do

  class RedGlassApp < Sinatra::Base

    red_glass_port = ENV['red_glass_port'].nil? ? 4567 : ENV['red_glass_port']
    socket = nil
    is_socket_connected = false
    events = Array.new

    get '/' do
      erb :index
    end

    post '/' do
      event = JSON.parse(params[:event_json])
      uuid = UUID.new
      event['id'] = uuid.generate
      events << event
      if is_socket_connected
        socket.send events.to_json
        events.clear
      end
    end

    get '/status' do
      'ready'
    end

    get '/kill' do
      Process.kill('INT', 0)
    end

    EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
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

    RedGlassApp.run!({:port => red_glass_port})
  end
end