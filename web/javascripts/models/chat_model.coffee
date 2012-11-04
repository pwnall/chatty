# Model for a chat room.
class ChatModel
  constructor: ->
    @users = {}
    @title = null
    @roomVersion = null

    @events = {}
    @firstEventId = null
    @lastEventId = null

  addList: (roomList) ->
    @title = roomList.title
    @users = {}
    for user in roomList.presence
      @users[user.name] = user
    @roomVersion += 1

  addEvent: (event) ->
    @firstEventId = event.id if @firstEventId is null
    return false if @lastEventId is not null and event.id != @lastEventId + 1
    @events[event.id] = event
    @lastEventId = event.id

    switch event.type
      when 'join'
        unless event.session2
          @users[event.name] = { name: event.name }
          @roomVersion += 1
      when 'part'
        unless event.session2
          delete @users[event.name]
          @roomVersion += 1

  getEvent: (eventId) -> @events[eventId]

  getAllEvents: ->
    return [] if @lastEventId is null
    @events[i] for i in[@firstEventId..@lastEventId]

  roomInfoVersion: -> @roomVersion

  getRoomInfo: ->
    users = []
    for own name, userInfo of @users
      users.push userInfo
    { title: @title, users: users }

