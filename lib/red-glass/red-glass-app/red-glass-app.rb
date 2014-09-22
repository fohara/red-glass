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
  SERVER_KEY = "#{File.dirname(__FILE__).to_s}/server.key"
  SERVER_CERT = "#{File.dirname(__FILE__).to_s}/server.crt"


  before do
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  end

  options '*' do
    response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS,POST'
    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  end

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
      RedGlassApp.run!({:port => red_glass_port}) do |server|
        ssl_options = {
            :cert_chain_file => SERVER_CERT,
            :private_key_file => SERVER_KEY,
            :verify_peer => false
        }
        server.ssl = true
        server.ssl_options = ssl_options
      end
      EventMachine::WebSocket.start({host: '0.0.0.0',
                                      port: 4568,
                                    secure: true,
                                    tls_options: {
                                        private_key_file: SERVER_KEY,
                                        cert_chain_file: SERVER_CERT
                                    }}) do |ws|
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