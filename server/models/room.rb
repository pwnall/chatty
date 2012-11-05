# :nodoc: namespace
module Chatty

# All the responsibilities of a chat room, such as notifications and logging.
#
# A chat room is exclusively owned by a single chat server, so there should
# never be two Room instances with the same name, in the whole system.
class Room
  attr_reader :name

  # Pulls the room with the given name from the database, or creates a new room.
  #
  # Args:
  #   name:: the room name to look up
  #   db:: the Mongo database backing chat logs
  #
  # Returns nil. The newly created Room instance is yielded asynchronously, most
  # likely after the method returns.
  def self.named(name, db, &block)
    room_history = db.collection('room_history')

    # Always load 2 history fragments, so we have enough history even if the
    # newest fragment is almost empty.
    cursor = room_history.find({room_name: name},
                               sort: [:last_event_id, :desc], limit: 2).to_a
    cursor.callback do |histories|
      events = histories.reverse.
                         map { |h| h['events'].map(&:symbolize_keys) }.
                         reduce [], :concat
      block.call self.new(name, events, histories.first, db)
    end
    nil
  end

  def ack_new_session(session, is_first_session)
    user = session.user
    @users[user.name] ||= user

    event :type => 'join', :name => user.name, :session2 => !is_first_session,
          :name_color => session.name_color
    nil
  end

  def ack_closed_session(session, is_last_session)
    user = session.user
    return nil unless @users[user.name]  # User already removed from the room.
    @users.delete user.name if is_last_session

    event :type => 'part', :name => user.name, :session2 => !is_last_session,
          :name_color => session.name_color
    nil
  end

  def av_event(user, type, av_nonce, name_color, client_timestamp)
    case type
    when 'av-accept'
      @users.each do |name, user|
        user.sessions.each do |session|
          if session.room == self and session.av_nonce == av_nonce
            session.av_nonce = nil
          end
        end
      end
    end

    event :type => type, :name => user.name, :av_nonce => av_nonce,
          :name_color => name_color, :client_ts => client_timestamp
  end

  def message(user, text, name_color, client_timestamp)
    event :type => 'text', :name => user.name, :text => text,
          :name_color => name_color, :client_ts => client_timestamp
  end

  def events_after(last_known_id)
    events = []
    i = 1
    while i <= @events.length && @events[-i][:id] > last_known_id
      events << @events[-i]
      i += 1
    end
    events.reverse
  end

  def recent_events(count)
    length = [count, @events.length].min
    @events[-length, length]
  end

  def presence_info
    response = []
    @users.each do |name, user|
      user.sessions.each do |session|
        next unless session.room == self
        response << session.presence_info
      end
    end
    response
  end

  # Relays a message between two users.
  #
  # Unlike events, relayed messages are not persisted, so they cannot survive
  # hardware issues. Relayed messages are intended to help users establish a
  # direct connection, e.g. by using ICE, and should not be used to transmit
  # user data.
  def relay(from_user, to_user_name, body, client_timestamp)
    message = { relays: [
        { from: from_user.name, body: body, client_ts: client_timestamp }] }
    @users.each do |name, user|
      next unless user.name == to_user_name
      user.sessions.each do |session|
        session.respond message if session.room == self
      end
    end
  end

  # Private constructor. Use Room::named instead.
  #
  # Args:
  #   name:: the room's name
  #   events:: array of hashes containing event data for the room
  #   last_history:: Mongo document containing this room's most recent fragment
  #                  of chat history
  #   db:: the Mongo database backing chat logs
  #
  # NOTE: Room::named fetches the old events for a room.
  def initialize(name, events, last_history, db)
    @db = db
    @name = name
    @events = events
    if @events.empty?
      @next_event_id = 0
    else
      @next_event_id = @events.last[:id] + 1
    end

    if last_history
      @history_length = last_history['events'].length
      @history_id = last_history['_id']
    else
      @history_length = 0
      @history_id = BSON::ObjectId.new
    end
    @users = {}
  end
  private :initialize

  # Saves and broadcasts an event that happened in the chat room.
  #
  # This method is called internally by methods such as add_user and message.
  # It should not be called directly.
  #
  # Args:
  #   data:: Hash containing the event details, such as a message's author and
  #          content
  #
  # Returns nil and completes asynchronously.
  def event(data)
    # Prepare the event object.
    id = @next_event_id
    @next_event_id += 1
    event = data.merge :id => id, :server_ts => Time.now.to_f
    @events << event

    # Write the event to persistent storage.
    if @history_length == 1_000
      @history_length = 0
      @history_id = BSON::ObjectId.new
    end
    @history_length += 1
    rr = @db.collection('room_history').safe_update({:_id => @history_id},
        {'$set' => {:last_event_id => event[:id], :room_name => @name},
         '$push' => {:events => event}}, :upsert => true)
    rr.callback do
      # Broadcast the event to users.
      @users.each do |name, user|
        user.sessions.each do |session|
          session.sync_events if session.room == self
        end
      end
    end
  end
  private :event
end  # class Chatty::Room

end  # namespace Chatty
