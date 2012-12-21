class StatusView
  constructor: (box) ->
    @$networkWin = $('.status-bar .network-ok', box)
    @$networkError = $('.status-bar .network-error', box)
    @$avLive = $('.status-bar .av-live', box)
    @$avError = $('.status-bar .av-error', box)

  showNetworkError: (message) ->
    @$networkWin.removeClass 'visible'
    @$networkError.addClass 'visible'
    @$networkError.attr 'title', message || 'Network Malfunction'

  showNetworkWin: (message) ->
    @$networkError.removeClass 'visible'
    @$networkWin.addClass 'visible'
    @$networkWin.attr 'title', message || 'Connected'

  showAvError: (message) ->
    @$avLive.removeClass 'visible'
    @$avError.addClass 'visible'
    @$avError.attr 'title', message || 'Video Malfunction'

  showAvLiveStatus: (isAvLive) ->
    if isAvLive
      @$avLive.addClass 'visible'
    else
      @$avLive.removeClass 'visible'


