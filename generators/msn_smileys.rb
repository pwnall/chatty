#!/usr/bin/env ruby
#
# Run from the project directory by executing
#     bundle exec generators/msn_smileys.rb
require 'bundler/setup'

require 'fileutils'
require 'json'
require 'net/http'
require 'nokogiri'
require 'uri'

# Scrape the MSN help page to get the icons and shortcuts.
page = URI.parse('http://messenger.msn.com/Resource/Emoticons.aspx')
doc = Nokogiri::HTML Net::HTTP.get(page)
emoticons = []
doc.css('.etable').css('tr').each do |tr|
  next unless tr.css('td img').length == tr.css('td span.bold:first').length
  tr.css('td').each do |td|
    if (image_set = td.css('img')).length == 1
      emoticons << {} if emoticons.empty? || emoticons.last[:url]
      emoticons.last[:url] = page.merge image_set.attr('src').to_s
    end
    if (text_set = td.css('span.bold')).length >= 1
      emoticons << {} if emoticons.empty? || emoticons.last[:texts]
      emoticons.last[:texts] = text_set.map { |t| t.inner_text }.
                                        reject(&:empty?)
    end
  end
end
emoticons.select! { |e| e[:url] && e[:texts] && !e[:texts].empty? }

# Fetch the images.
root = 'web/public/images/smileys'
FileUtils.mkdir_p root
emoticons.each_with_index do |emoticon, index|
  url = emoticon[:url]
  extension = File.basename(url.path).split('.').last
  filename = File.join root, "m#{index}.#{extension}"
  File.open(filename, 'wb') { |f| f.write Net::HTTP.get url }
  emoticon[:file] = filename.split('/', 2).last
end

# Map in Gtalk shortcuts.
aliases = {
  ':-)' => ['=)'],
  ';-)' => [';^)'],
  ':-(' => ['=('],
  ':-D' => [':D', '=D'],
  '(L)' => ['<3'],
  '(U)' => ['</3'],
  '(K)' => [':-*', ':*', ':-x'],
  ':-@' => ['X-(', 'X(', 'x-(', 'x('],
  '(H)' => ['B-)', 'b-)'],
  '*-)' => [':/', ':-/', '=/'],
  '(6)' => ['}:-)'],
  ':-P' => [':-p', ':P', '=P']
}

json = {:smileys => []}
emoticons.each do |emoticon|
  emoticon[:texts].each do |text|
    json[:smileys] << { :text => text, :file => emoticon[:file] }
    (aliases[text] || []).each do |atext|
      json[:smileys] << { :text => atext, :file => emoticon[:file] }
    end
  end
end
File.open('lib/emotes_m.json', 'w') { |f| f.write json.to_json }
