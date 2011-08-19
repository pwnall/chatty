#!/usr/bin/env ruby

# Activate gems.
require 'rubygems'
require 'bundler'
Bundler.setup :default, :chat
require 'active_support/core_ext'
require 'em-mongo'
require 'eventmachine'

# Load up the server code.
Dir[File.expand_path('..', __FILE__) + '/chatty/**/*.rb'].each { |f| require f }

EventMachine.run do
  # Set up the components.
  db = EventMachine::Mongo::Connection.new('localhost').db('chatty')
  nexus = Chatty::Nexus.new db
  ws_server = Chatty::WebSocketServer.new nexus
  
  # Event loop.
  ws_server.run
end
