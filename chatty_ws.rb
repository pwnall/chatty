#!/usr/bin/env ruby
require 'bundler/setup'

require 'em-websocket'
require 'json'
require 'set'

# A chat room.
class Room
  attr_reader :name
  
  def initialize(name)
    @name = name
    @users = {}
    @events = {}
    @next_event_id = 0
  end
  
  def add_user(user)
    return false if @users[user.name]  # Already added.
    
    event :type => 'join', :name => user.name
    @users[user.name] = user
    true
  end
  
  def remove_user(user)
    return false unless @users[user.name]  # Already removed.
    @users.delete user.name
    event :type => 'part', :name => user.name
    true
  end
  
  def message(user, text)
    event :type => 'text', :name => user.name, :text => text
  end
  
  def event(data)
    id = @next_event_id
    event = data.merge :id => @next_event_id, :time => Time.now.gmtime
    @events[id] = event
    @next_event_id += 1
    @users.each do |name, user|
      user.sessions.each do |session|
        session.sync_events if session.room == self
      end
    end
  end
  
  def events_after(last_known_id)
    events = []
    while last_known_id < @next_event_id - 1
      last_known_id += 1
      events << @events[last_known_id]
    end
    events
  end
  
  def recent_events(count)
    events = []
    [count, @next_event_id].min.downto(1) do |i|
      events << @events[@next_event_id - i]
    end
    events
  end
end  # class Room

# A chat user.
class User
  attr_reader :name
  attr_reader :sessions
  
  def initialize(name)
    @name = name
    @sessions = Set.new
    @rooms = {}
  end
  
  def add_session(session)
    @sessions << session
    room_name = session.room.name
    if @rooms[room_name]
      @rooms[room_name] += 1
    else
      @rooms[room_name] = 1
      session.room.add_user session.user
    end
  end
  
  def remove_session(session)
    @sessions.delete session
    
    room_name = session.room.name
    return unless @rooms[room_name]
    @rooms[room_name] -= 1
    if @rooms[room_name] == 0
      @rooms.delete room_name
      session.room.remove_user session.user
    end
  end
end  # class User

# A user's browser session.
class Session
  attr_reader :user
  attr_reader :room
  
  def initialize(web_socket, server)
    @ws = web_socket
    @server = server
    @user = nil
    @room = nil
    @nonces = Set.new
  end
  
  # Called after the WebSocket handshake completes.
  def connected(query)
    user_name = query['name']
    room_name = query['room']
    if user_name && room_name
      @user = @server.user_named user_name
      @room = @server.room_named room_name

      @user.add_session self
      events = @room.recent_events(10)
      respond_recent_events events
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
  def received(data)
    case data[:type]
    when 'text'
      return if @nonces.include?(data[:nonce])
      @nonces << data[:nonce]
      room.message @user, data[:text]
    when 'sync'
      @last_event_id = data[:last_event_id].to_i
      sync_events
    end
  end
  
  # Transmits any events that the client might not know about.
  def sync_events
    events = @room.events_after @last_event_id
    return if events.empty?
    respond_recent_events events
  end

  # Returns the latest events to the client.
  #
  # Args:
  #   events:: an array of events; the code assumes these are the most recent
  #            events in the session's room
  def respond_recent_events(events)
    last_id = events.last[:id]
    respond :last_event_id => last_id, :events => events
    @last_event_id = last_id
  end

  # Returns data to the client.
  def respond(data)
    @ws.send JSON.unparse(data)
  end
end  # class Session

class Server
  def initialize
    @users = {}
    @rooms = {}
  end

  def user_named(name)
    @users[name] ||= User.new name
  end
 
  def room_named(name)
    @rooms[name] ||= Room.new name
  end
  
  def run
    server = self
    EventMachine.run do
      EventMachine::WebSocket.start :host => '0.0.0.0', :port => 9494 do |ws|
        session = Session.new ws, server
        ws.onopen { session.connected ws.request['query'] }
        ws.onclose { session.closed }
        ws.onmessage do |m|
          if m.respond_to?(:encoding) && m.encoding != 'UTF-8'
            m.force_encoding 'UTF-8'
          end
          session.received JSON.parse(m, :symbolize_names => true)
        end
      end
    end
  end
end

Server.new.run