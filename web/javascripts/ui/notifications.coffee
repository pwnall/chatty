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
    permissions = @backend.checkPermission()
    if permissions is (@backend.PERMISSION_ALLOWED or 0)
      @prompted = true
      @allowed = true
    if permissions is (@backend.PERMISSION_NOT_ALLOWED or 1)
      @prompted = false
      @allowed = false
    if permissions is (@backend.PERMISSION_DENIED or 2)
      @prompted = true
      @allowed = false

  # WebKit implementation of requestPermission.
  webkitRequestPermission: ->
    @backend.requestPermission => @queryPermission

# Application-specific implementation for desktop notifications.
class DesktopNotifications extends DesktopNotificationsBase
  # Shows the permission prompt, if necessary.
  constructor: (@chatbox, @$composer) ->
    super
    @notifications = {}
    @focused = document.hasFocus()
    window.addEventListener 'focus', (=> @onWindowFocus()), true
    window.addEventListener 'blur', (=> @onWindowBlur()), true

    unless @prompted
      $prompt = $('.notification-bar .desktop', @chatbox)
      $prompt.addClass 'visible'
      $prompt.click (event) =>
        $prompt.removeClass 'visible'
        @requestPermission()
        event.preventDefault()
        false

  # Issues any notifications that may be relevant for a new event.
  serverEvent: (event) ->
    return if @focused or not @allowed
    if event.type is 'text'
      author = event.name
      icon = '/images/icons/chat32.png'

      @notifications[author].cancel() if @notifications[author]
      post = @post icon, "#{author} says", "#{event.text}"
      post.onclick = =>
        window.focus()
        @$composer.focus()
      @notifications[author] = post

  # Keeps track of the chat window's focus status.
  onWindowBlur: ->
    @focused = false

  # Dismisses all notifications when the chat window regains focus.
  onWindowFocus: ->
    @focused = true
    for author, notification of @notifications
      notification.cancel()
    @notifications = {}
