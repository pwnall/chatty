# Model for a chat room.
class ChatModel
  constructor: ->
    @events = {}
    @firstEventId = null
    @lastEventId = null
    
  addEvent: (event) ->
    @firstEventId = event.id unless @firstEventId
    return false if @lastEventId and event.id != @lastEventId + 1
    @events[event.id] = event
    @lastEventId = event.id
    
  getEvent: (eventId) -> @events[eventId]
    
  getAllEvents: -> @events[i] for i in[@firstEventId..@lastEventId] 

# Interfaces with the WS chat server.
class ChatController
  constructor: (@view, @ws_uri) ->
    @model = new ChatModel
    view.onMessageSubmission = (text) => @submitMessage text
    @connect()
  
  connect: ->
    @ws = new WebSocket(@ws_uri)
    @ws.onclose = => @onSocketClose
    @ws.onerror = (error) => @onSocketEror error
    @ws.onmessage = (event) => @onMessage JSON.parse(event.data)
  
  onSocketClose: ->
    @view.disableComposer()
    @view.showInfo 'disconnected'

  onSocketError: (errorMessage) ->
    @view.disableComposer()
    @view.wsError errorMessage
    setTimeout (=> @connect), 1000
    
    
  onMessage: (data) ->
    @view.enableComposer()
    @view.showInfo ':)'
    if data.events
      @model.addEvent(event) for event in data.events
      @view.update @model
      
  submitMessage: (text) ->
    @socketSend type: 'text', text: text

  socketSend: (data) ->
    @ws.send JSON.stringify(data)
  
  
# The view for a chat box.
class ChatView
  constructor: (@box) ->
    @$box = $(box)
    @$form = $('.composer', box)
    @$history = $('.history', box)
    @$message = $('.message', box)
    @$title = $('.title', box)
    @$status = $('.status-bar', box)
    @$message.val ''
    @$form.keydown (event) => @onKeyDown event
    @$onMessageSubmission = ->
  
  onKeyDown: (event) ->
    if event.keyCode is 13 and !event.shiftKey
      event.preventDefault()
      text = @$message.val()
      @$message.val ''
      @onMessageSubmission text
  
  enableComposer: ->
    @$message.attr('disabled', false)
  
  disableComposer: ->
    @message.attr('disabled', true)
  
  showError: (message) ->
    @setStatusClass 'error'
    @$status.text ':)'
    
  showSuccess: (message) ->
    @setStatusClass 'win'
    @$status.text message

  showInfo: (message) ->
    @setStatusClass 'info'
    @$status.text message

  setStatusClass: (klass) ->
    @$status.removeClass(kklass) for kklass in ['error', 'info', 'win']
    @$status.addClass klass
    
  update: (model) ->
    start = @lastEventId()
    if start
      for eventId in [@lastEventId()..model.lastEventId]
        @appendEvent(model.getEvent(eventId))
    else
      for event in model.getAllEvents()
        @appendEvent(event)
    
  appendEvent: (event) ->
    $dom = $('<li><span class="time" /><span class="author" /></li>')
    time = new Date(Date.parse(event.time))
    timeString = [time.getHours(), ':', Math.floor(time.getMinutes() / 10),
                  time.getMinutes() % 10].join('')
    $dom.attr('data-id', event.id);
    $('.time', $dom).text(timeString);
    $('.author', $dom).text(event.name);
    switch event.type
      when 'text'
        $dom.append '<span class="message" />'
        $('.message', $dom).text event.text
      when 'join'
        $dom.append '<span class="event">joined the chat</span>'
      when 'part'
        $dom.append '<span class="event">left the chat</span>'
    @$history.prepend $dom
    
    setTimeout (=> @$history[0].scrollTop = @$history[0].scrollHeight), 10
  
  lastEventId: ->
    event_id = parseInt $('li:first', @$history).attr('data-id')
    return event_id or NaN

# Sets up everything when the document loads.
$ ->
  $('.chat-box').each (index, element) ->
    view = new ChatView element
    controller = new ChatController view, $(element).attr('data-server')
    window.controller = controller
    view.showInfo 'connecting'
