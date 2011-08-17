require 'set'

# :nodoc: namespace
module Chatty

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
end  # class Chatty::User

end  # namespace Chatty
