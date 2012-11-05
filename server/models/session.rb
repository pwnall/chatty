require 'json'

# :nodoc: namespace
module Chatty

# A user's browser session.
class Session
  attr_reader :user
  attr_reader :room
  attr_reader :name_color
  attr_accessor :av_nonce

  def initialize(web_socket, nexus)
    @ws = web_socket
    @nexus = nexus
    @user = nil
    @room = nil
    @nonces = Set.new

    @name_color = nil  # Set by the user.
    @av_nonce = nil    # Set by the user.
  end

  # Called after the WebSocket handshake completes.
  def connected(query)
    user_name = query['name']
    room_name = query['room']
    @name_color = query['name_color'] || '000000'
    if user_name && room_name
      @nexus.user_named user_name do |user|
        @user = user
        @nexus.room_named room_name do |room|
          @room = room
          @user.add_session self
          respond list: { title: @room.name, presence: @room.presence_info }
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
      room.message @user, data[:text], @name_color, data[:client_ts]
    when 'av-invite', 'av-accept', 'av-close'
      return if @nonces.include?(data[:nonce])
      @nonces << data[:nonce]
      av_message data
    when 'sync'
      @last_event_id = data[:last_event_id].to_i
      sync_events
    when 'ping'
      respond pong: { nonce: data[:nonce], client_ts: data[:client_ts] }
    when 'relay'
      return if @nonces.include?(data[:nonce])
      @nonces << data[:nonce]
      room.relay @user, data[:to], data[:body], data[:client_ts]
    end
  end

  # Called by #received to process A/V events.
  def av_message(message_data)
    case message_data['type']
    when 'av-invite'
      @av_nonce = message_data[:av_nonce]
    when 'av-accept'
      # NOTE: room#av_event takes care of av-accept
    when 'av-close'
      @av_nonce = nil if @av_nonce == message_data[:av_nonce]
    end

    room.av_event @user, message_data[:type], message_data[:av_nonce],
                  @name_color, message_data[:client_ts]
  end

  # Returns a JSON hash describing the session info for this user.
  def presence_info
    {
      name: @user.name,
      name_color: @name_color,
      av_nonce: @av_nonce
    }
  end

  # Transmits any events that the client might not know about.
  def sync_events
    events = @last_event_id ? @room.events_after(@last_event_id) :
                              @room.recent_events(512)
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
