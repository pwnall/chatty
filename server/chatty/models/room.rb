# :nodoc: namespace
module Chatty

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
  
  def message(user, text, client_timestamp)
    event :type => 'text', :name => user.name, :text => text,
          :client_ts => client_timestamp
  end
  
  def event(data)
    id = @next_event_id
    event = data.merge :id => @next_event_id, :server_ts => Time.now.to_f
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
end  # class Chatty::Room

end  # namespace Chatty
