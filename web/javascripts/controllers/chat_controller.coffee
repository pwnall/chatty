# Interfaces with the WS chat server.
class ChatController
  constructor: (@view, @wsUri) ->
    @model = new ChatModel
    @ws = null
    @pingController = new PingController this
    @rtcController = new RtcController this
    @view.onMessageSubmission = (text) => @submitMessage text
    @connect()

  connect: ->
    @disconnect()
    @ws = new WebSocket(@wsUri)
    @ws.onclose = => @onSocketClose
    @ws.onerror = (error) => @onSocketEror error
    @ws.onmessage = (event) => @onMessage JSON.parse(event.data)

    @view.showInfo 'connecting'
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

  onSocketClose: ->
    @disconnect()
    @view.disableComposer()
    @view.showError 'disconnected'

  onSocketError: (errorMessage) ->
    @disconnect()
    @view.disableComposer()
    @view.showError errorMessage
    setTimeout (=> @connect()), 5000

  onPingTimeout: ->
    @onSocketError 'network issues'

  onMessage: (data) ->
    @view.enableComposer()
    @view.showInfo 'connected'
    if data.events
      @model.addEvent(event) for event in data.events
      @view.update @model
    if data.pong
      @pingController.onPong data.pong
    @pingController.resetTimer()

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
