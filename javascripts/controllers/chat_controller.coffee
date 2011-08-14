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
