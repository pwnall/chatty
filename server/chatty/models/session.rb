require 'json'

# :nodoc: namespace
module Chatty

# A user's browser session.
class Session
  attr_reader :user
  attr_reader :room
  
  def initialize(web_socket, nexus)
    @ws = web_socket
    @nexus = nexus
    @user = nil
    @room = nil
    @nonces = Set.new
  end
  
  # Called after the WebSocket handshake completes.
  def connected(query)
    user_name = query['name']
    room_name = query['room']
    if user_name && room_name
      @nexus.user_named user_name do |user|
        @user = user
        @nexus.room_named room_name do |room|
          @room = room
          @user.add_session self
        end
      end
    else
      @ws.close_websocket
    end
  end
  
  # Called when the client closes the WebSocket.
  def closed
    if @user && @room
      @user.remove_session self
      @room = nil
    end
  end
  
  # Called when the client sends some data.
  def received(message)
    if message.respond_to?(:encoding) && message.encoding != 'UTF-8'
      message.force_encoding 'UTF-8'
    end
    data = JSON.parse message, :symbolize_names => true
    
    case data[:type]
    when 'text'
      return if @nonces.include?(data[:nonce])
      @nonces << data[:nonce]
      room.message @user, data[:text], data[:client_ts]
    when 'sync'
      @last_event_id = data[:last_event_id].to_i
      sync_events
    end
  end
  
  # Transmits any events that the client might not know about.
  def sync_events
    events = @last_event_id ? @room.events_after(@last_event_id) :
                              @room.recent_events(25)
    return if events.empty?
    respond_recent_events events
  end

  # Returns the latest events to the client.
  #
  # Args:
  #   events:: an array of events; the code assumes these are the most recent
  #            events in the session's room
  def respond_recent_events(events)
    return if events.empty?
    
    last_id = events.last[:id]
    respond :last_event_id => last_id, :events => events
    @last_event_id = last_id
  end

  # Returns data to the client.
  def respond(data)
    @ws.send JSON.unparse(data)
  end
end  # class Chatty::Session

end  # namespace Chatty
