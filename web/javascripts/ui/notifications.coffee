# Common infrastructure for any desktop notification controller.
class DesktopNotificationsBase
  constructor: ->
    @backend = window.Notification or window.webkitNotifications
    @queryPermission()

  # Creates and shows a desktop notification.
  #
  # Returns a Notification instance.
  post: (icon, title, text) ->
    if typeof @backend is 'function'
      # W3C standard.
      post = new @backend title, body: text, icon: icon, lang: 'en'
    else if @backend.createNotification
      # WebKit variant.
      post = @backend.createNotification icon, title, text
      post.show()
    else
      post = null
    post

  # Removes a notification displayed by calling post.
  remove: (notification) ->
    if notification.close
      # W3C standard.
      notification.close()
    else if notification.cancel
      # WebKit variant.
      notification.cancel()
    else
      null

  # Asks the notification engine if we're allowed to post notifications.
  #
  # Sets the instance variables @prompted (if the user has been prompted to
  # enable desktop notifications) and @allowed (if we're allowed to post
  # notifications).
  queryPermission: ->
    # If there's no notification support, pretend we were denied access.
    @prompted = true
    @allowed = false
    if @backend.permission
      # W3C standard.
      permission = @backend.permission
      switch permission
        when 'granted'
          @prompted = true
          @allowed = true
        when 'default'
          @prompted = false
          @allowed = false
        when 'denied'
          @prompted = true
          @allowed = false
    else if @backend.checkPermission
      # WebKit variant.
      permission = @backend.checkPermission()
      switch permission
        when 0  # PERMISSION_ALLOWED
          @prompted = true
          @allowed = true
        when 1  # PERMISSION_NOT_ALLOWED
          @prompted = false
          @allowed = false
        when 2  # PERMISSION_DENIED
          @prompted = true
          @allowed = false
    else if window.webkitNotifications and webkitNotifications.checkPermission
      # Chrome, because of http://crbug.com/163226
      permission = webkitNotifications.checkPermission()
      switch permission
        when 0  # PERMISSION_ALLOWED
          @prompted = true
          @allowed = true
        when 1  # PERMISSION_NOT_ALLOWED
          @prompted = false
          @allowed = false
        when 2  # PERMISSION_DENIED
          @prompted = true
          @allowed = false

    return

  # Asks the user to allow us to post desktop notifications.
  requestPermission: ->
    if @backend.requestPermission
      @backend.requestPermission => @queryPermission()
    else
      false

# Application-specific implementation for desktop notifications.
class DesktopNotifications extends DesktopNotificationsBase
  # Shows the permission prompt, if necessary.
  constructor: (@chatbox, @$composer) ->
    super
    @notifications = {}
    @visible = @isVisible()
    if document.visibilityState
      eventName = 'visibilitychange'
    else if document.webkitVisibilityState
      eventName = 'webkitvisibilitychange'
    else
      eventName = null

    if eventName
      document.addEventListener eventName, (=> @onVisibilityChange()), false

    unless @prompted
      $prompt = $('.status-bar .desktop', @chatbox)
      $prompt.addClass 'visible'
      $prompt.click (event) =>
        $prompt.removeClass 'visible'
        @requestPermission()
        event.preventDefault()
        false

  # True if the application's tab is visible by the user.
  isVisible: ->
    visibilityState = document.visibilityState or
                      document.webkitVisibilityState
    (not visibilityState) or (visibilityState is 'visible')

  # Issues any notifications that may be relevant for a new event.
  serverEvent: (event) ->
    return if @visible or not @allowed

    if event.type is 'text'
      author = event.name
      icon = "#{document.location.origin}/images/icons/chat32.png"

      @remove @notifications[author] if @notifications[author]
      post = @post icon, "#{author} says", "#{event.text}"
      post.onclick = =>
        window.focus()
        @$composer.focus()
      @notifications[author] = post

  # Keeps track of the chat window's visibility state.
  onVisibilityChange: ->
    @visible = @isVisible()
    if @visible
      for author, notification of @notifications
        @remove notification
      @notifications = {}
