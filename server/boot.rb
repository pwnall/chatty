#!/usr/bin/env ruby

# Activate gems.
require 'rubygems'
require 'bundler'
Bundler.setup :default, :chat

# Load up the server code.
Dir[File.expand_path('..', __FILE__) + '/chatty/**/*.rb'].each { |f| require f }

# Set up the components.
nexus = Chatty::Nexus.new
ws_server = Chatty::WebSocketServer.new nexus

# Event loop.
EventMachine.run do
  ws_server.run
end
