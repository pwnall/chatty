# Detects network timeout issues.
class PingController
  constructor: (@chatController) ->
    @pingTimerHandler = => @onPingTimer()
    @pingTimer = null

    @pongTimerHandler = => @onPongTimer()
    @pongTimer = null
    @pongNonce = null

    @pingInterval = 30
    @roundTrip = 20.0

  resetTimer: ->
    @disableTimer()
    @pingTimer = window.setTimeout @pingTimerHandler, @pingInterval * 1000

  disableTimer: ->
    if @pongTimer isnt null
      window.clearTimeout @pongTimer
      @pongTimer = null
      @pongNonce = null
    if @pingTimer isnt null
      window.clearTimeout @pingTimer
      @pingTimer = null

  onPong: (data) ->
    if @pongNonce is data.nonce and data.client_ts
      roundTrip = Date.now() / 1000 - data.client_ts
      @roundTrip = @roundTrip * 0.2 + roundTrip * 0.8

  onPingTimer: ->
    return if @pingTimer is null
    @pingTimer = null
    # No need to send a ping if we already have one on the way.
    return if @pongTimer isnt null

    @pongNonce = @chatController.nonce()
    @chatController.socketSend(
        type: 'ping', nonce: @pongNonce, client_ts: Date.now() / 1000)
    @pongTimer = window.setTimeout @pongTimerHandler, @roundTrip + 5000

  onPongTimer: ->
    return if @pongTimer is null
    @pongTimer = null

    @disableTimer()
    @chatController.onPingTimeout()

