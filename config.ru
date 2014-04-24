require 'rack'
require 'pry-debugger'
require 'rack/websocket'

class SocketzApp < Rack::WebSocket::Application
  def on_open(env)
    connection = @websocket_handler.connection
    SocketChannels.add_connection(connection)
    puts "Number of channels: #{SocketChannels.channels.count}"
    puts "Number of connections: #{SocketChannels.channels.first.connections.count}"
    puts "Client connected"
    # binding.pry
    # @websocket_handler.connection.socket.request.env['PATH_INFO']
    # connection.send "Hello to you!"
  end

  def on_close(env)
    puts "Client disconnected"
  end

  def on_message(env, msg)
    puts "Received message: " + msg
    channel = SocketChannels.channels.first
    channel.broadcast "OP?"
    # send_data "I'm fine, and how are you?"
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

# map '/' do
#   run HttpApp.new
# end

# map '/socketz' do
#   run SocketzApp.new
# end

class SocketChannels

  @@channels = []

  def self.add_connection(connection)
    env = connection.socket.request.env
    channel_name = env['PATH_INFO'].sub('/', '')

    if SocketChannels.has_channel?(channel_name)
      SocketChannels.get_channel(channel_name).connections << connection
    else
      socket_channel = SocketChannel.new(channel_name)
      socket_channel.connections << connection
      SocketChannels.push(socket_channel)
    end
  end

  def self.remove_connection(connection)

  end

  def self.channels
    @@channels
  end

  def self.push(channel)
    if has_channel?(channel.name)
      raise "Can't add the same channel twice!"
    else
      @@channels << channel
    end
  end

  def self.has_channel?(name)
    @@channels.any? {|channel| channel.name == name}
  end

  def self.get_channel(name)
    @@channels.find {|channel| channel.name == name}
  end

end

class SocketChannel 
  attr_reader :name
  attr_accessor :connections

  def initialize(name)
    @name = name
    self.connections = []
  end

  def broadcast(msg)
    connections.each do |connection|
      connection.send msg
    end
  end

end


class HttpSocketz
  def call(env)
    if env['HTTP_UPGRADE'] == "websocket"
      # channel_name = env['PATH_INFO'].sub('/', '')
      # connection = env["HTTP_SEC_WEBSOCKET_KEY"]

      # if SocketChannels.has_channel?(channel_name)
      #   binding.pry
      #   SocketChannels.get_channel(channel_name).connections << connection
      # else
      #   socket_channel = SocketChannel.new(channel_name)
      #   socket_channel.connections << connection
      #   SocketChannels.push(socket_channel)
      # end

      SocketzApp.new.call(env)
    else
      HttpApp.new.call(env)
    end
  end
end

run HttpSocketz.new