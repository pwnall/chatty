# The view for a chat box.
class ChatView
  constructor: (box: box, emoticons: @emoticons) ->
    @onMessageSubmission = ->

    @$box = $(box)
    @$form = $('.composer', box)
    @$history = $('.history', box)
    @$message = $('.composer .message', box)
    @$title = $('.title', box)
    @$status = $('.status-bar', box)
    @$message.val ''

    @$form.keydown (event) => @onKeyDown event
    @$box.click (event) =>
      @$message.focus()
      event.preventDefault()
      
    @desktop_notifications = new DesktopNotifications box, @$message
  
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
    @desktop_notifications.serverEvent event 
  
  lastEventId: ->
    attr = $('li:last', @$history).attr('data-id')
    if attr then parseInt(attr) else null
  
  messageDom: (text) ->
    $dom = $('<span class="message" />')
    tokens = @emoticons.parseText text
    for token in tokens
      if token instanceof Element
        $dom.append token
      else
        $span = $('<span class="text">')
        $span.text(token)
        $dom.append $span
    $dom
