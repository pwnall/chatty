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
    @view.showInfo 'connected'
    if data.events
      @model.addEvent(event) for event in data.events
      @view.update @model
      
  submitMessage: (text) ->
    @socketSend
      type: 'text', text: text, nonce: @nonce(),
      client_ts: Date.now() / 1000

  socketSend: (data) ->
    @ws.send JSON.stringify(data)
  
  nonce: ->
    timestamp = (new Date()).getTime().toString 36
    random = Math.floor(Math.random() * 0x7fffffff).toString 36
    [random, timestamp].join '.'

# The view for a chat box.
class ChatView
  constructor: (@box) ->
    @onMessageSubmission = ->

    @$box = $(box)
    @$form = $('.composer', box)
    @$history = $('.history', box)
    @$message = $('.message', box)
    @$title = $('.title', box)
    @$status = $('.status-bar', box)
    @$message.val ''

    @$form.keydown (event) => @onKeyDown event
    @$box.click (event) =>
      @$message.focus()
      event.preventDefault()
  
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
    last = @lastEventId()
    if last is null
      for event in model.getAllEvents()
        @appendEvent(event)
    else
      for eventId in [(last + 1)..model.lastEventId]
        @appendEvent(model.getEvent(eventId))
    
  appendEvent: (event) ->
    $dom = $('<li><span class="time" /><span class="author" /></li>')
    time = new Date event.server_ts * 1000
    timeString = [time.getHours(), ':', Math.floor(time.getMinutes() / 10),
                  time.getMinutes() % 10].join ''
    $dom.attr 'data-id', event.id
    $('.time', $dom).text timeString
    $('.author', $dom).text event.name
    switch event.type
      when 'text'
        $dom.append '<span class="message" />'
        $('.message', $dom).text event.text
      when 'join'
        $dom.append '<span class="event">joined the chat</span>'
      when 'part'
        $dom.append '<span class="event">left the chat</span>'
    if event.client_ts and Math.abs(event.server_ts - event.client_ts) >= 10
      $('.time', $dom).addClass 'delayed'
      $('.author', $dom).addClass 'delayed'
      $dom.attr 'title', 'This message was delayed by the Internet. ' +
                         'It may be out of context.'

    @$history.append $dom
    
    setTimeout (=> @$history[0].scrollTop = @$history[0].scrollHeight), 10
  
  lastEventId: ->
    attr = $('li:last', @$history).attr('data-id')
    if attr then parseInt(attr) else null

# Sets up everything when the document loads.
$ ->
  $('.chat-box').each (index, element) ->
    view = new ChatView element
    controller = new ChatController view, $(element).attr('data-server')
    window.controller = controller
    view.showInfo 'connecting'
