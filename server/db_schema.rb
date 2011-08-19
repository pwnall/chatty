#!/usr/bin/env ruby

# Activate gems.
require 'rubygems'
require 'bundler'
Bundler.setup :default, :db_schema

# Connect to the database. Creates the database if necessary.
require 'mongo'
db = Mongo::Connection.new['chatty']

# Collection and index for chat logs.
room_history = db['room_history']
room_history.create_index [['room_name', Mongo::ASCENDING],
                           ['last_event_id', Mongo::DESCENDING]]
