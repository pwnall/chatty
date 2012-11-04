# WebRTC-assisted A/V chat.
class RtcController
  constructor: (@chatController) ->
    @chatView = @chatController.chatView
    @avView = @chatView.avView
    @statusView = @chatView.statusView
    @avView.onAvClick = (event) => @onAvClick event

    @rtcAddStreamHandler = (event) => @onRtcAddStream event
    @iceCandidateHandler = (event) => @onIceCandidate event
    @iceChangeHandler = (event) => @onIceChange event
    @rtcNegotiationHandler = (event) => @onRtcNegotiationNeeded event
    @rtcOpenHandler = (event) => @onRtcOpen event
    @rtcRemoveStreamHandler = (event) => @onRtcRemoveStream event
    @rtcChangeHandler = (event) => @onRtcChange event

    @rtcOfferSuccessHandler = (sdp) => @onRtcOfferSdp sdp
    @rtcLocalDescriptionSuccessHandler = => @onRtcLocalDescriptionSuccess()
    @rtcErrorHandler = (errorText) => @onRtcError errorText


    @rtcReset()

  onAvClick: (event) ->
    event.preventDefault()
    event.stopPropagation()
    @avInput()

  # Checks for getUserMedia support.
  computeSupported: ->
    return false unless @rtc

    # NOTE: the method is more complex than it should be, to match avInput
    if navigator.getUserMedia
      return true
    if navigator.webkitGetUserMedia
      return true
    if navigator.mozGetUserMedia
      return true
    false

  # Prompts the user for permission to use the A/V inputs.
  avInput: ->
    media = { video: true, audio: true }
    callback = (stream) => @onAvInputStream stream
    if navigator.getUserMedia
      navigator.getUserMedia media, callback
    if navigator.webkitGetUserMedia
      navigator.webkitGetUserMedia media, callback
    if navigator.mozGetUserMedia
      navigator.mozGetUserMedia media, callback

  # Called when the user's A/V inputs are provided to the application.
  onAvInputStream: (stream) ->
    console.log 'onAvInputStream'
    @avView.showLocalVideo stream
    @rtc.addStream stream
    @rtc.createOffer @rtcOfferSuccessHandler, @rtcErrorHandler

  # Re-initializes the RTC state after an error occurs.
  rtcReset: ->
    if @rtc
      @rtc.onaddstream = null
      @rtc.onicecandidate = null
      @rtc.onincechange = null
      @rtc.onnegotiationneeded = null
      @rtc.onopen = null
      @rtc.onremovestream = null
      @rtc.onstatechange = null
      @rtc.close()

    @rtc = @rtcConnection()
    @supported = @computeSupported()
    if @supported
      @avView.enableAvButton()
    else
      @avView.disableAvButton()
      @statusView.showAvError 'Your browser does not support video chat'


  # Creates an RTCPeerConnection.
  rtcConnection: ->
    config = RtcController.rtcConfig()
    if window.RTCPeerConnection
      rtc = new RTCPeerConnection(config)
    else if window.webkitRTCPeerConnection
      rtc = new webkitRTCPeerConnection(config)
    else if window.mozRTCPeerConnection
      rtc = new mozRTCPeerConnection(config)
    else
      return null

    rtc.onaddstream = @rtcAddStreamHandler
    rtc.onicecandidate = @iceCandidateHandler
    rtc.onincechange = @iceChangeHandler
    rtc.onnegotiationneeded = @rtcNegotiationHandler
    rtc.onopen = @rtcOpenHandler
    rtc.onremovestream = @rtcRemoveStreamHandler
    rtc.onstatechange = @rtcChangeHandler
    rtc

  # Called when the remote side added a stream to the connection.
  onRtcAddStream: (event) ->
    console.log ['addStream', event]
    @avView.showRemoteVideo event.stream

  # Called when the remote side removed a stream from the connection.
  onRtcRemoveStream: (event) ->
    console.log ['removeStream', event]
    @avView.hideVideo()
    @rtcReset()

  # Called when ICE has a candidate-something. (incomplete spec)
  onIceCandidate: (event) ->
    console.log ['iceCandidate', event]

  # Called when the ICE agent makes some progress. (incomplete spec)
  onIceChange: (event) ->
    console.log ['iceChange', event]
    # if event.type is 'negotiationneeded'
    #   @onRtcNegotiationNeeded event

  # Called when network changes require an ICE re-negotiation.
  onRtcNegotiationNeeded: (event) ->
    console.log ['iceChange', event]

  # Called when something opens. (incomplete spec)
  onRtcOpen: (event) ->
    console.log ['rtcOpen', event]

  # Called when the RTC state changes.
  onRtcChange: (event) ->
    console.log ['rtcChange', event]

  # Called when RTCPeerConnection.createOffer succeeds.
  onRtcOfferSdp: (sdp) ->
    console.log ['rtcOfferSuccess', sdp]
    @rtc.setLocalDescription sdp, @rtcLocalDescriptionSuccessHandler,
                             @rtcErrorHandler

  # Called when RTCPeerConnection.setLocalDescription succeeds.
  onRtcLocalDescriptionSuccess: ->
    console.log ['rtcLocalDescripionSuccess']

  # Called when a step in the RTC process fails.
  onRtcError: (errorText) ->
    @statusView.showAvError errorText
    @avView.hideVideo()
    @rtcReset()

  # RTCPeerConnection configuration.
  @rtcConfig: ->
    iceServers: ({ url: "stun:#{url}" } for url in @stunServers())

  # Array of STUN servers that can be used by WebRTC.
  @stunServers: ->
    [
      "stun.l.google.com:19302",
      "stun1.l.google.com:19302",
      "stun2.l.google.com:19302",
      "stun3.l.google.com:19302",
      "stun4.l.google.com:19302",
      "stun01.sipphone.com",
      "stun.ekiga.net",
      "stun.fwdnet.net",
      "stun.ideasip.com",
      "stun.iptel.org",
      "stun.rixtelecom.se",
      "stun.schlund.de",
      "stunserver.org",
      "stun.softjoys.com",
      "stun.voiparound.com",
      "stun.voipbuster.com",
      "stun.voipstunt.com",
      "stun.voxgratia.org",
      "stun.xten.com",
    ]

