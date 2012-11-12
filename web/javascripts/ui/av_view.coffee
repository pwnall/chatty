class AvView
  constructor: (box) ->
    @$box = $(box)

    @$avContainer = $('.av-container', box)
    @$localVideo = $('video.local', @$avContainer)
    @localVideo = @$localVideo[0]
    @$remoteVideo = $('video.remote', @$avContainer)
    @remoteVideo = @$remoteVideo[0]

    @$partnerName = $('.partner-name', box)
    @$avButton = $('.av-button', box)
    @$avButton.click (event) => @onAvClick event

  onAvClick: (event) ->
    null  # RtcController overrides this hook

  onAvAccept: (avNonce, avPartnerName) ->
    null  # RtcController overrides this hook

  # Event relayed by ChatView.
  onAvAcceptClick: (event) ->
    $button = $(event.target).closest '[data-av-partner][data-av-nonce]'
    avNonce = $button.attr 'data-av-nonce'
    avPartnerName = $button.attr 'data-av-partner'
    @onAvAccept avNonce, avPartnerName

  enableAvControls: ->
    @$box.removeClass 'av-hidden'

  disableAvControls: ->
    @$box.addClass 'av-hidden'

  showLocalVideo: (stream) ->
    @$avContainer.addClass 'no-remote'
    @localVideo.src = window.URL.createObjectURL stream
    @$avContainer.removeClass 'hidden'

  showRemoteVideo: (stream) ->
    @$avContainer.addClass 'remote'
    @$avContainer.removeClass 'no-remote'
    @remoteVideo.src = window.URL.createObjectURL stream
    @$avContainer.removeClass 'hidden'

  showPartnerName: (avPartnerName) ->
    @$partnerName.text avPartnerName || 'waiting for a partner...'

  hideVideo: ->
    @showPartnerName null
    @localVideo.src = null
    @remoteVideo.src = null
    @$avContainer.removeClass 'remote'
    @$avContainer.removeClass 'no-remote'
    @$avContainer.addClass 'hidden'
