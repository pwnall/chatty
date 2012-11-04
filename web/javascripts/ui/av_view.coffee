class AvView
  constructor: (box: box) ->
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

  enableAvButton: ->
    @$avButton.removeClass 'hidden'

  disableAvButton: ->
    @$avButton.addClass 'hidden'

  showLocalVideo: (stream) ->
    @$partnerName.text 'placing call...'
    @$avContainer.addClass 'no-remote'
    @localVideo.src = window.URL.createObjectURL stream
    @$avContainer.removeClass 'hidden'

  showRemoteVideo: (stream) ->
    @$avContainer.addClass 'remote'
    @$avContainer.removeClass 'no-remote'
    @remoteVideo.src = window.URL.createObjectURL stream
    @$avContainer.removeClass 'hidden'

  hideVideo: ->
    @$partnerName.text 'loading...'
    @localVideo.src = null
    @remoteVideo.src = null
    @$avContainer.removeClass 'remote'
    @$avContainer.removeClass 'no-remote'
    @$avContainer.addClass 'hidden'
