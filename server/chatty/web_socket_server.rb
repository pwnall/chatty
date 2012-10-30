require 'em-websocket'
require 'json'

# :nodoc: namespace
module Chatty

class WebSocketServer
  def initialize(nexus, log)
    @nexus = nexus
    @log = log
  end

  def host
    @host ||= '0.0.0.0'
  end
  def port
    @port ||= (ENV['PORT'] ? ENV['PORT'].to_i : 9494)
  end

  def run
    @log.info "Listening on #{host} port #{port}"
    EventMachine::WebSocket.start :host => host, :port => port do |ws|
      session = Session.new ws, @nexus
      ws.onopen { session.connected ws.request['query'] }
      ws.onclose { session.closed }
      ws.onmessage { |m| session.received m }
    end
  end
end  # class Chatty::WebSocketServer

end  # namespace Chatty
