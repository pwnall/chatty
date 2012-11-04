# WebRTC-assisted A/V chat.
class RtcController
  constructor: ->
    @rtc = @rtcConnection()

  # Checks for getUserMedia support.
  hasAvInput: ->
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
  onAvInput: (stream) ->


  # Creates an RTCPeerConnection.
  rtcConnection: ->
    config = RtcController.rtcConfig()
    console.log config
    if window.RTCPeerConnection
      return new RTCPeerConnection(config)
    if window.webkitRTCPeerConnection
      return new webkitRTCPeerConnection(config)
    if window.mozRTCPeerConnection
      return new mozRTCPeerConnection(config)
    nil

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

