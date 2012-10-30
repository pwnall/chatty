require 'em-websocket'
require 'English'
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
    @log.info "Server PID #{$PID}, listening on #{host} port #{port}"
    EventMachine::WebSocket.start :host => host, :port => port do |ws|
      session = Session.new ws, @nexus
      ws.onopen do
        @log.debug "WebSocket opened: #{ws.request.inspect}"
        session.connected ws.request['query']
      end
      ws.onclose do
        @log.debug 'WebSocket closed'
        session.closed
      end
      ws.onmessage { |m| session.received m }
    end
  end
end  # class Chatty::WebSocketServer

end  # namespace Chatty
