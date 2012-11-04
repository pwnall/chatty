require 'bundler'
Bundler.setup :default, :web

require './web/application.rb'

require 'webrick/httputils'
if File.exist?('/etc/mime.types')
  list = WEBrick::HTTPUtils.load_mime_types('/etc/mime.types')
  Rack::Mime::MIME_TYPES.merge!(list)
end
Rack::Mime::MIME_TYPES.merge!  '.ttf' => 'application/x-font-ttf',
                               '.woff' => 'application/x-font-woff'

use Rack::Deflater
run Chatty
