# Interfaces with the WS chat server.
class ChatController
  constructor: (@chatView, @wsUri) ->
    @model = new ChatModel
    @ws = null
    @pingController = new PingController this
    @rtcController = new RtcController this
    @chatView.onMessageSubmission = (text) => @submitMessage text
    @statusView = @chatView.statusView
    @connect()

  connect: ->
    @disconnect()
    @ws = new WebSocket(@wsUri)
    @ws.onclose = => @onSocketClose()
    @ws.onerror = (error) => @onSocketEror error
    @ws.onopen = => @onSocketOpen()
    @ws.onmessage = (event) => @onMessage JSON.parse(event.data)

    @statusView.showNetworkError 'Connecting'
    @pingController.resetTimer()

  disconnect: ->
    @pingController.disableTimer()
    return if @ws is null

    @ws.close()
    # Disconnect the event handlers so we don't get spurious events.
    @ws.onmessage = null
    @ws.onerror = null
    @ws.onclose = null
    @ws = null

  onSocketOpen: ->
    return unless @ws
    @sendListQuery()
    @chatView.enableComposer()
    @statusView.showNetworkWin 'Connected'

  onSocketClose: ->
    @disconnect()
    @chatView.disableComposer()
    if @ws
      @statusView.showNetworkError 'Server Down'
      setTimeout (=> @connect()), 30000
    else
      @onSocketError 'Disconnected'

  onSocketError: (errorMessage) ->
    @disconnect()
    @chatView.disableComposer()
    @statusView.showNetworkError errorMessage
    setTimeout (=> @connect()), 5000

  onPingTimeout: ->
    @onSocketError 'network issues'

  onMessage: (data) ->
    if data.events
      for event in data.events
        @model.addEvent event
        @rtcController.onAvEvent(event) if event.av_nonce
      @chatView.update @model
    if data.list
      @model.addList data.list
      @chatView.update @model
    if data.pong
      @pingController.onPong data.pong
    if data.relays
      for relay in data.relays
        @rtcController.onAvRelay(relay) if relay.body?.av_nonce
    @pingController.resetTimer()

  submitMessage: (text) ->
    @submitEvent type: 'text', text: text

  submitEvent: (event) ->
    event.nonce = @nonce()
    event.client_ts = Date.now() / 1000
    @socketSend event

  sendRelay: (receiverName, body) ->
    @socketSend(
        type: 'relay', to: receiverName, body: body, nonce: @nonce(),
        client_ts: Date.now() / 1000)

  sendListQuery: ->
    @socketSend type: 'list', nonce: @nonce(), client_ts: Date.now() / 1000

  socketSend: (data) ->
    @ws.send JSON.stringify(data)

  nonce: ->
    timestamp = (new Date()).getTime().toString 36
    random = Math.floor(Math.random() * 0x7fffffff).toString 36
    [random, timestamp].join '.'
