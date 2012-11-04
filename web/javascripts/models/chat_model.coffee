# Model for a chat room.
class ChatModel
  constructor: ->
    @events = {}
    @firstEventId = null
    @lastEventId = null
    
  addEvent: (event) ->
    @firstEventId = event.id if @firstEventId is null
    return false if @lastEventId is not null and event.id != @lastEventId + 1
    @events[event.id] = event
    @lastEventId = event.id
    
  getEvent: (eventId) -> @events[eventId]
    
  getAllEvents: -> @events[i] for i in[@firstEventId..@lastEventId] 
