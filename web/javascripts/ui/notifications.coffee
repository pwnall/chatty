# Common infrastructure for any desktop notification controller.
class DesktopNotificationsBase
  constructor: ->
    if window.webkitNotifications
      @configureWebkit()
    # TODO(pwnall): HTML5 spec-compliant engine, when an implementation becomes
    #               available, so we can test against it

    @queryPermission()

  # Creates and shows a desktop notification.
  #
  # Returns a
  post: (title, text) ->
    # NOTE: this is a stub, so we give up right away.
    false

  # Asks the notification engine if we're allowed to post notifications.
  #
  # Sets the instance variables @prompted (if the user has been prompted to
  # enable desktop notifications) and @allowed (if we're allowed to post
  # notifications).
  queryPermission: ->
    # NOTE: this is a stub, so it's safe to pretend we can't post.
    @prompted = true
    @allowed = false

  # Asks the user to allow us to post desktop notifications.
  requestPermission: ->
    # NOTE: this is a stub, so we give up right away.
    false

  # Desktop notifications will be served using the WebKit backend.
  configureWebkit: ->
    @backend = window.webkitNotifications
    @post = @webkitPost
    @queryPermission = @webkitQueryPermission
    @requestPermission = @webkitRequestPermission

  # WebKit implementation of post.
  webkitPost: (icon, title, text) ->
    post = @backend.createNotification icon, title, text
    post.show()
    post

  # WebKit implementation of checkPermission.
  webkitQueryPermission: ->
    permission = @backend.checkPermission()
    if permission is (@backend.PERMISSION_ALLOWED or 0)
      @prompted = true
      @allowed = true
    if permission is (@backend.PERMISSION_NOT_ALLOWED or 1)
      @prompted = false
      @allowed = false
    if permission is (@backend.PERMISSION_DENIED or 2)
      @prompted = true
      @allowed = false

  # WebKit implementation of requestPermission.
  webkitRequestPermission: ->
    @backend.requestPermission => @queryPermission()

# Application-specific implementation for desktop notifications.
class DesktopNotifications extends DesktopNotificationsBase
  # Shows the permission prompt, if necessary.
  constructor: (@chatbox, @$composer) ->
    super
    @notifications = {}
    @visible = @isVisible()
    eventName = 'visiblitychange'
    if document.visibilityState
      eventName = 'visibilitychange'
    else if document.webkitVisibilityState
      eventName = 'webkitvisibilitychange'
    else if document.mozVisibilityState
      eventName = 'mozvisibilitychange'
    else if document.msVisibilityState
      eventName = 'msvisibilitychange'
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
        document.webkitVisibilityState or document.mozVisibilityState or
        document.msVisibilityState
    (not visibilityState) or (visibilityState is 'visible')

  # Issues any notifications that may be relevant for a new event.
  serverEvent: (event) ->
    return if @visible or not @allowed

    if event.type is 'text'
      author = event.name
      icon = "#{document.location.origin}/images/icons/chat32.png"

      @notifications[author].cancel() if @notifications[author]
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
        notification.cancel()
      @notifications = {}
