require 'rack'
require 'pry-debugger'
require 'rack/websocket'

class SocketzApp < Rack::WebSocket::Application
  def on_open(env)
    puts "Client connected"
    send_data "Hello to you!"
  end

  def on_close(env)
    puts "Client disconnected"
  end

  def on_message(env, msg)
    puts "Received message: " + msg
    send_data "I'm fine, and how are you?"
  end

  def on_error(env, error)
    puts "Error occured: " + error.message
  end

end

class HttpApp
  def call env
    [200, {"Content-Type" => "text/html"}, [File.read('index.html')]]
  end
end

map '/' do
  run HttpApp.new
end

map '/socketz' do
  run SocketzApp.new
end