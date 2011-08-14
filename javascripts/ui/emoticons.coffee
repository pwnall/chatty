# Spruces up messages with smileys.
class Emoticons
  # Sets up blank data structures and fires an AJAX call to get smiley info.
  constructor: (@onLoad = null) ->
    @codes = []
    @codes_regexp = null
    @images = {}
    @onLoad ||= ->
    $.getJSON '/emotes_m.json', (data) => @onData(data)

  # Breaks up a message into smileys and regular text.
  #
  # Returns an array, whose elements are either Strings containing text
  # fragments, or DOM elements representing the smileys.
  parseText: (text) ->
    return [text] unless @codes_regexp
    parts = text.split @codes_regexp
    for i in [0...parts.length]
      if i % 2 is 0 then parts[i] else @smileyDom parts[i]

  # DOM element representing a smiley.
  smileyDom: (smileyText) ->
    $element = $('<img class="smiley" />')
    $element.attr 'src', @images[smileyText]
    $element.attr attr, smileyText for attr in ['alt', 'title']
    $element[0]

  # Initializes the data structurs for real, after the AJAX call completes.
  onData: (data) ->
    if data.smileys
      @codes = (smiley.text for smiley in data.smileys)
      @codes_regexp = @splitRegExp @codes
      for smiley in data.smileys
        @images[smiley.text] = smiley.file
    @onLoad(@)
    
  # RegExp that .split()s up a string into smileys and non-smiley regions.
  #
  # Looks like (smiley1|smiley2|...|smileyn), and RegExp special characters are
  # properly escaped.
  splitRegExp: (codes) ->
    re_specials = /[[\]{}()*+?.\\|^$\-,&#\s]/g
    codes_re = (text.replace(re_specials, '\\$&') for text in @codes).join '|'
    new RegExp ['(', codes_re, ')'].join('')
