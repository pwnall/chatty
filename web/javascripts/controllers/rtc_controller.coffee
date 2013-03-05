# WebRTC-assisted A/V chat.
class RtcController
  constructor: (@chatController) ->
    @chatView = @chatController.chatView
    @avView = @chatView.avView
    @statusView = @chatView.statusView
    @avView.onAvClick = (event) => @onAvClick event
    @avView.onAvAccept = (avNonce, avPartnerName) =>
        @onAvAccept avNonce, avPartnerName

    @supported = @computeSupported()
    @avReset()
    @rtcReset()

    @rtcAddStreamHandler = (event) => @onRtcAddStream event
    @iceCandidateHandler = (event) => @onIceCandidate event
    @iceChangeHandler = (event) => @onIceChange event
    @rtcNegotiationHandler = (event) => @onRtcNegotiationNeeded event
    @rtcOpenHandler = (event) => @onRtcOpen event
    @rtcRemoveStreamHandler = (event) => @onRtcRemoveStream event
    @rtcChangeHandler = (event) => @onRtcChange event

    @rtcOfferSuccessHandler = (sessDescription) =>
      @onRtcOfferCreate sessDescription
    @rtcAnswerSuccessHandler = (sessDescription) =>
      @onRtcAnswerCreate sessDescription
    @rtcLocalDescriptionSuccessHandler = => @onRtcLocalDescriptionSuccess()
    @rtcRemoteDescriptionSuccessHandler = => @onRtcRemoteDescriptionSuccess()
    @rtcErrorHandler = (errorText) => @onRtcError errorText

  # Called when the user clicks on the A/V button.
  onAvClick: (event) ->
    event.preventDefault()
    event.stopPropagation()

    if @calling or @answering
      @rtcReset()
      @avReset()
      # TODO(pwnall): send hangup
    else
      @calling = true
      @avNonce = @chatController.nonce()
      @avInput()

  # Called when the user accepts an A/V invitation.
  onAvAccept: (avNonce, avPartnerName) ->
    return if @calling or @answering

    @answering = true
    @avNonce = avNonce
    @setAvPartnerName avPartnerName
    @avInput()

  # Prompts the user for permission to use the A/V inputs.
  avInput: ->
    media = { video: true, audio: true }
    callback = (stream) => @onAvInputStream stream
    errorCallback = (error) => @onAvInputError error
    if navigator.getUserMedia
      navigator.getUserMedia media, callback, errorCallback
    if navigator.webkitGetUserMedia
      navigator.webkitGetUserMedia media, callback, errorCallback
    if navigator.mozGetUserMedia
      navigator.mozGetUserMedia media, callback, errorCallback

  # Called when the user's A/V inputs are provided to the application.
  onAvInputStream: (stream) ->
    if @localStream
      @localStream.stop() if @localStream.stop
    @localStream = stream
    @avView.showLocalVideo @localStream
    @statusView.showAvLiveStatus true
    if @calling
      @chatController.submitEvent type: 'av-invite', av_nonce: @avNonce
      @avNoncePublished = true
    else if @answering
      @rtcConnect()
      if @rtc
        @chatController.submitEvent type: 'av-accept', av_nonce: @avNonce
        @avNoncePublished = true
    else
      @rtcReset()
      @avReset()

  # Called when an A/V event is issued in the room.
  onAvEvent: (event) ->
    switch event.type
      when 'av-accept'
        if @calling and event.av_nonce is @avNonce and !@avPartnerName
          @setAvPartnerName event.name
          @rtcConnect()
      when 'av-close'
        if event.av_nonce is @avNonce and event.name is @avPartnerName
          @avReset()
          @rtcReset()

  # Called when A/V control information is received
  onAvRelay: (relay) ->
    if relay.from isnt @avPartnerName or relay.body.av_nonce isnt @avNonce
      return

    switch relay.body.type
      when 'rtc-description'
        if relay.body.description
          description = new RTCSessionDescription relay.body.description
          @rtc.setRemoteDescription description,
              @rtcRemoteDescriptionSuccessHandler, @rtcErrorHandler
      when 'rtc-ice'
        if relay.body.candidate
          candidate = new RTCIceCandidate relay.body.candidate
          @rtc.addIceCandidate candidate

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
      @rtc = null

    if @supported
      @avView.enableAvControls()
    else
      @avView.disableAvControls()
      @statusView.showAvError 'Your browser does not support video chat'

  # Re-initializes the A/V state after an error occurs.
  avReset: ->
    @avView.hideVideo()
    if @localStream
      @localStream.stop() if @localStream.stop
      @localStream = null
    if @remoteStream
      @remoteStream.stop() if @remoteStream.stop
      @remoteStream = null
    @statusView.showAvLiveStatus false

    if @avNonce and @avNoncePublished
      @chatController.submitEvent type: 'av-close', av_nonce: @avNonce
    @avNonce = null
    @setAvPartnerName null
    @calling = false
    @answering = false
    @avNoncePublished = false

  # Creates a RTCPeerConnection and kicks off the ICE process.
  rtcConnect: ->
    unless @rtc = @rtcConnection()
      @avReset()
      @rtcReset()
      return

    @rtc.addStream @localStream

  # Creates an RTCPeerConnection.
  rtcConnection: ->
    config = RtcController.rtcConfig()
    if window.RTCPeerConnection and
        typeof window.RTCPeerConnection is 'function'
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
    @log ['addStream', event]
    if @remoteStream
      @remoteStream.stop() if @remoteStream.stop
    @remoteStream = event.stream
    @avView.showRemoteVideo @remoteStream

  # Called when the remote side removed a stream from the connection.
  onRtcRemoveStream: (event) ->
    @log ['removeStream', event]
    @avView.hideVideo()
    @rtcReset()

  # Called when ICE has a candidate-something. (incomplete spec)
  onIceCandidate: (event) ->
    @chatController.sendRelay(@avPartnerName,
        type: 'rtc-ice', candidate: event.candidate, av_nonce: @avNonce)

  # Called when the ICE agent makes some progress. (incomplete spec)
  onIceChange: (event) ->
    @log ['iceChange', event]

  # Called when network changes require an ICE re-negotiation.
  onRtcNegotiationNeeded: (event) ->
    @log ['rtcNegotiationNeeded', event]
    if @calling
      @rtc.createOffer @rtcOfferSuccessHandler, @rtcErrorHandler

  # Called when something opens. (incomplete spec)
  onRtcOpen: (event) ->
    @log ['rtcOpen', event]

  # Called when the RTC state changes.
  onRtcChange: (event) ->
    @log ['rtcChange', event]

  # Called when RTCPeerConnection.createOffer succeeds.
  onRtcOfferCreate: (sessDescription) ->
    @rtc.setLocalDescription sessDescription,
        @rtcLocalDescriptionSuccessHandler, @rtcErrorHandler
    @chatController.sendRelay(@avPartnerName,
        type: 'rtc-description', description: sessDescription,
        av_nonce: @avNonce)

  # Called when RTCPeerConnection.createAnswer succeeds.
  onRtcAnswerCreate: (sessDescription) ->
    @rtc.setLocalDescription sessDescription,
        @rtcLocalDescriptionSuccessHandler, @rtcErrorHandler
    @chatController.sendRelay(@avPartnerName,
        type: 'rtc-description', description: sessDescription,
        av_nonce: @avNonce)

  # Called when RTCPeerConnection.setLocalDescription succeeds.
  onRtcLocalDescriptionSuccess: ->
    @log ['rtcLocalDescripionSuccess']

  # Called when RTCPeerConnection.setRemoteDescription succeeds.
  onRtcRemoteDescriptionSuccess: ->
    @log ['rtRemoteDescripionSuccess']
    if @answering
      @rtc.createAnswer @rtcAnswerSuccessHandler, @rtcErrorHandler

  # Called when a step in the RTC process fails.
  onRtcError: (errorText) ->
    @statusView.showAvError errorText
    @avView.hideVideo()
    @rtcReset()

  # Called when there is a failure in getting video.
  #
  # The most likely failure is the user didn't grant us permissions.
  onAvInputError: (errorText) ->
    @statusView.showAvError errorText
    @avView.hideVideo()
    @rtcReset()


  # Called when we know who we're talking to.
  setAvPartnerName: (avPartnerName) ->
    @avPartnerName = avPartnerName
    @avView.showPartnerName @avPartnerName

  # Checks for getUserMedia and RTCPeerConnection support.
  computeSupported: ->
    @isRtcPeerConnectionSupported() && @isUserMediaSupported()

  isRtcPeerConnectionSupported: ->
    # NOTE: this method is overly complex, to match rtcConnection
    if window.RTCPeerConnection
      return true
    else if window.webkitRTCPeerConnection
      return true
    else if window.mozRTCPeerConnection
      return true
    else
      return false

  isUserMediaSupported: ->
    # NOTE: the method is overly complex, to match avInput
    if navigator.getUserMedia
      return true
    if navigator.webkitGetUserMedia
      return true
    if navigator.mozGetUserMedia
      return true
    false

  # Logs progress for the purpose of debugging.
  log: (data) ->
    if window.location.host == 'localhost' and console and console.log
      console.log data

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
      "numb.viagenie.ca",
      "stun.counterpath.net",
      # Firefox doesn't do DNS resolution here :/
      # This is stun.l.google.com
      "173.194.78.127:19302"
    ]

