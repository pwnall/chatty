#!/usr/bin/env ruby

# Activate gems.
require 'rubygems'
require 'bundler'
Bundler.setup :default, :chat
require 'active_support/core_ext'
require 'em-mongo'
require 'eventmachine'
require 'logger'

# Load up the server code.
Dir[File.expand_path('..', __FILE__) + '/**/*.rb'].each do |f|
  require f
end

EventMachine.run do
  # Set up the components.
  log = Logger.new STDERR
  log.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::INFO
  db = EventMachine::Mongo::Connection.new('localhost').db('chatty')
  nexus = Chatty::Nexus.new db, log
  ws_server = Chatty::WebSocketServer.new nexus

  # Event loop.
  ws_server.run
end
