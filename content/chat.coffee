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
        $dom.append @messageDom(event.text)
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
  
  messageDom: (text) ->
    $dom = $('<span class="message" />')
    tokens = Emoticons.parseText text
    for token in tokens
      if token instanceof Element
        $dom.append token
      else
        $span = $('<span class="text">')
        $span.text(token)
        $dom.append $span
    $dom
    
# Spruces up messages with smileys.
class Emoticons
  # Sets up blank data structures and fires an AJAX call to get smiley info.
  @initialize: (@onLoad = null) ->
    @codes = []
    @codes_regexp = null
    @images = {}
    @onLoad ||= ->
    $.getJSON '/emotes_m.json', (data) => @onData(data)

  # Breaks up a message into smileys and regular text.
  #
  # Returns an array, whose elements are either Strings containing text
  # fragments, or DOM elements representing the smileys.
  @parseText: (text) ->
    return [text] unless @codes_regexp
    parts = text.split @codes_regexp
    for i in [0...parts.length]
      if i % 2 is 0 then parts[i] else @smileyDom parts[i]

  # DOM element representing a smiley.
  @smileyDom: (smileyText) ->
    $element = $('<img class="smiley" />')
    $element.attr 'src', @images[smileyText]
    $element.attr attr, smileyText for attr in ['alt', 'title']
    $element[0]

  # Initializes the data structurs for real, after the AJAX call completes.
  @onData: (data) ->
    if data.smileys
      @codes = (smiley.text for smiley in data.smileys)
      @codes_regexp = @splitRegExp @codes
      for smiley in data.smileys
        @images[smiley.text] = smiley.file
    @onLoad()
    
  # RegExp that .split()s up a string into smileys and non-smiley regions.
  #
  # Looks like (smiley1|smiley2|...|smileyn), and RegExp special characters are
  # properly escaped.
  @splitRegExp: (codes) ->
    re_specials = /[[\]{}()*+?.\\|^$\-,&#\s]/g
    codes_re = (text.replace(re_specials, '\\$&') for text in @codes).join '|'
    new RegExp ['(', codes_re, ')'].join('')
  
# Sets up everything when the document loads.
$ ->
  Emoticons.initialize ->
    $('.chat-box').each (index, element) ->
      view = new ChatView element
      controller = new ChatController view, $(element).attr('data-server')
      view.showInfo 'connecting'
      
      # Debugging convenience.
      window.controller = controller
      window.emoticons = Emoticons
      