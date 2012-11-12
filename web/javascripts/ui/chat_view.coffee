# The view for a chat box.
class ChatView
  constructor: (box: box, emoticons: @emoticons) ->
    @onMessageSubmission = ->

    @$style = $('style', box)
    @cssClasses = {}

    @$box = $(box)

    @$form = $('.composer', box)
    @$sendButton = $('.send-button', box)
    @$history = $('.history', box)
    @$message = $('.composer .message', box)
    @$message.val ''

    @roomVersion = null
    @$title = $('.room-title', box)
    @$users = $('.user-list', box)

    @$form.keydown (event) => @onKeyDown event
    @$sendButton.click (event) => @onSendClick event
    @$box.click (event) =>
      @$message.focus()
      event.preventDefault()

    @statusView = new StatusView box
    @desktopNotifications = new DesktopNotifications box, @$message

    @avView = new AvView box
    @avAcceptHandler = (event) => @avView.onAvAcceptClick event

  onKeyDown: (event) ->
    if event.keyCode is 13 and !event.shiftKey
      event.preventDefault()
      @onSendClick event

  onSendClick: (event) ->
    text = @$message.val()
    @$message.val ''
    @onMessageSubmission text

  enableComposer: ->
    @$message.removeAttr 'disabled'

  disableComposer: ->
    @$message.attr 'disabled', true

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
        $li = $ "<li class=\"#{@cssClassFor(userInfo)}\">" +
            '<i class="icon-user icon-large"></i> ' +
            '<span class="name"></span> ' +
            '<button type="button">' +
            '<i class="icon-facetime-video icon-large"></i>' +
            ' Join video chat</button></li>'
        $('.name', $li).text userInfo.name
        if userInfo.av_nonce
          $('button', $li).attr('title', "Videochat with #{userInfo.name}").
              attr('data-av-partner', userInfo.name).
              attr('data-av-nonce', userInfo.av_nonce).
              click @avAcceptHandler
        else
          $('button', $li).addClass 'hidden'
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
      when 'av-invite'
        $icon.addClass 'icon-facetime-video'
        $dom.append '<span class="event">made a video call</span>'
      when 'av-accept'
        $icon.addClass 'icon-facetime-video'
        $dom.append '<span class="event">answered a video call</span>'
      when 'av-close'
        $icon.addClass 'icon-facetime-video'
        $dom.append '<span class="event">hung up from a video call</span>'
    if event.client_ts and Math.abs(event.server_ts - event.client_ts) >= 10
      $dom.addClass 'delayed'
      $dom.attr 'title', 'This message was delayed by the Internet. ' +
                         'It may be out of context.'
    @$history.prepend $dom

    @desktopNotifications.serverEvent event

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
    ul.user-list > li.#{className} > .name {
      color: #{nameColor.hexString()};
    }
    ul.user-list > li.#{className} > i {
      color: #{iconColor.hexString()};
    }
    ul.history > li.#{className} {
      border-color: #{borderColor.hexString()};
      background-color: #{bgColor.hexString()};
    }
    ul.history > li.#{className} > i {
      color: #{iconColor.hexString()};
    }
    ul.history > li.#{className} > span.author {
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
