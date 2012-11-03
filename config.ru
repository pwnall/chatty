require 'bundler'
Bundler.setup :default, :web

require './chatty_web.rb'

use Rack::Deflater
run ChattyWeb
