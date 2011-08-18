#!/usr/bin/env ruby

# Activate gems.
require 'rubygems'
require 'bundler'
Bundler.setup :default, :db_schema

require 'mongo'
db = Mongo::Connection.new['chatty']

history_slugs = db['history_slugs']
