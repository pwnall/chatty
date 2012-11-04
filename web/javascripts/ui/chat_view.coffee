# The view for a chat box.
class ChatView
  constructor: (box: box, emoticons: @emoticons) ->
    @onMessageSubmission = ->

    @$style = $('style', box)
    @cssClasses = {}

    @$box = $(box)

    @$form = $('.composer', box)
    @$history = $('.history', box)
    @$message = $('.composer .message', box)
    @$message.val ''

    @roomVersion = null
    @$title = $('.room-title', box)
    @$users = $('.user-list', box)

    @$networkWin = $('.notification-bar .network-ok', box)
    @$networkError = $('.notification-bar .network-error', box)
    @$avLive = $('.notification-bar .av-live', box)
    @$avError = $('.notification-bar .av-error', box)

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
    @$message.removeAttr('disabled', false)

  disableComposer: ->
    @$message.attr('disabled', true)

  showNetworkError: (message) ->
    @$networkWin.removeClass 'visible'
    @$networkError.addClass 'visible'
    @$networkError.attr 'title', message || 'Network Malfunction'

  showNetworkWin: (message) ->
    @$networkError.removeClass 'visible'
    @$networkWin.addClass 'visible'
    @$networkWin.attr 'title', message || 'Connected'

  showAvError: (message) ->
    console.log message
    @$avLive.removeClass 'visible'
    @$avError.addClass 'visible'
    @$avError.attr 'title', message || 'Video Malfunction'

  updateAvLiveStatus: (isAvLive) ->
    if isAvLive
      @$avLive.addClass 'visible'
    else
      @$avLive.removeClass 'visible'

  update: (model) ->
    last = @lastEventId()
    if last is null
      for event in model.getAllEvents()
        @appendEvent(event)
    else if last < model.lastEventId
      for eventId in [(last + 1)..model.lastEventId]
        @appendEvent(model.getEvent(eventId))

    if @roomVersion != model.roomInfoVersion()
      @roomVersion = model.roomInfoVersion()
      roomInfo = model.getRoomInfo()
      if roomInfo.title
        @$title.text roomInfo.title
      users = roomInfo.users
      users.sort (a, b) -> a.name.localeCompare(b.name)
      @$users.empty()
      for userInfo in users
        $li = $ '<li><i class="icon-user icon-large"></i> <span class="name"></span></li>'
        $('.name', $li).text userInfo.name
        $li.attr 'data-name', userInfo.name
        @$users.append $li

  appendEvent: (event) ->
    cssClass = @cssClassFor event
    $dom = $("<li class=\"#{cssClass}\"><span class=\"time\"></span>" +
             "<i class=\"icon-large\"></i><span class=\"author\"></span></li>")
    time = new Date event.server_ts * 1000
    timeString = [time.getHours(), ':', Math.floor(time.getMinutes() / 10),
                  time.getMinutes() % 10].join ''
    $dom.attr 'data-id', event.id
    $('.author', $dom).text event.name
    $('.time', $dom).text timeString
    $icon = $('i', $dom)
    switch event.type
      when 'text'
        $icon.addClass 'icon-comment-alt'
        $dom.append @messageDom(event.text)
      when 'join'
        $icon.addClass 'icon-signin'
        $dom.append '<span class="event">joined the chat</span>'
      when 'part'
        $icon.addClass 'icon-signout'
        $dom.append '<span class="event">left the chat</span>'
    if event.client_ts and Math.abs(event.server_ts - event.client_ts) >= 10
      $dom.addClass 'delayed'
      $dom.attr 'title', 'This message was delayed by the Internet. ' +
                         'It may be out of context.'
    @$history.prepend $dom

    @desktop_notifications.serverEvent event

  cssClassFor: (event) ->
    key = event.name_color || '000000'
    return @cssClasses[key] if @cssClasses[key]

    className = 'name_color_' + key

    nameColor = Color('#' + (event.name_color || '000000'))
    if nameColor.saturation() == 0
      borderColor = Color(nameColor.hslString()).lightness(90)
      bgColor = Color(nameColor.hslString()).lightness(99)
      iconColor = Color(nameColor.hslString()).lightness(60)
    else
      borderColor = Color(nameColor.hslString()).lightness(90).saturation(50)
      bgColor = Color(nameColor.hslString()).lightness(99).saturation(50)
      iconColor = Color(nameColor.hslString()).lightness(60).saturation(25)

    rule = """
    li.#{className} {
      border-color: #{borderColor.hexString()};
      background-color: #{bgColor.hexString()};
    }
    li.#{className} > i {
      color: #{iconColor.hexString()};
    }
    li.#{className} > span.author {
      color: #{nameColor.hexString()};
    }
    """
    @$style.text @$style.text() + "\n" + rule

    @cssClasses[key] = className


  lastEventId: ->
    attr = $('li:first-child', @$history).attr('data-id')
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
