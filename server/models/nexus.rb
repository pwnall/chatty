# :nodoc: namespace
module Chatty

# Central location for a chat server's data.
#
# This class caches User and Room instances, and ensures against aliasing (the
# rest of the code will never see different Room or User objects pointing to the
# same user or room).
class Nexus
  # Prepares a nexus with a cold cache.
  #
  # Args:
  #   db:: Mongo database backing chat logs
  #   log:: Logger instance
  def initialize(db, log)
    @db = db
    @log = log
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
  # The Room instance is yielded, most likely after the call completes.
  def room_named(name, &block)
    if @rooms[name]
      block.call @rooms[name]
      return nil
    end

    Room.named name, @db do |new_room|
      # TODO: this goes in the db's response block
      @rooms[name] ||= new_room
      block.call @rooms[name]
    end
    nil
  end

  # The Logger instance used by this server.
  attr_reader :log
end  # class Chatty::Nexus

end  # namespace Chatty
