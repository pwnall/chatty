# Sets up everything when the document loads.
$ ->
   new Emoticons (emoticons) ->
    $('.chat-box').each (index, element) ->
      view = new ChatView box: element, emoticons: emoticons
      controller = new ChatController view, $(element).attr('data-server')

      # Debugging convenience.
      window.controller = controller

