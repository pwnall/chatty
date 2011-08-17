require 'em-websocket'
require 'json'

# :nodoc: namespace
module Chatty

class WebSocketServer
  def initialize(nexus)
    @nexus = nexus
  end
  
  def run
    EventMachine::WebSocket.start :host => '0.0.0.0', :port => 9494 do |ws|
      session = Session.new ws, @nexus
      ws.onopen { session.connected ws.request['query'] }
      ws.onclose { session.closed }
      ws.onmessage { |m| session.received m }
    end
  end
end  # class Chatty::WebSocketServer

end  # namespace Chatty
