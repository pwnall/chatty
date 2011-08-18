# :nodoc: namespace
module Chatty
  
# Central location for a chat server's data.
class Nexus
  # Prepares a nexus with a cold cache.
  def initialize
    @users = {}
    @rooms = {}
  end

  # Creates or retrieves a user.
  #
  # Returns nil.
  #
  # The User instance is yielded, possibly after the call completes.
  def user_named(name, &block)
    if @users[name]
      block.call @users[name]
      return nil
    end
    
    new_user = User.new name  # TODO: database create-or-fetch
    
    # TODO: this goes in the db's response block
    @users[name] ||= new_user
    block.call @users[name]

    nil
  end
  
  # Creates or retrieves a chat room.
  #
  # Returns nil.
  #
  # The User instance is yielded, possibly after the call completes.
  def room_named(name, &block)
    if @rooms[name]
      block.call @rooms[name]
      return nil
    end
    
    new_room = Room.new name  # TODO: database create-or-fetch
    
    # TODO: this goes in the db's response block
    @rooms[name] ||= new_room
    block.call @rooms[name]
    
    nil
  end
end  # class Chatty::Nexus

end  # namespace Chatty
