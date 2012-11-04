require 'bundler'
Bundler.setup :default, :web

require './web/application.rb'

use Rack::Deflater
run Chatty
