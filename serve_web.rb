#!/usr/bin/env ruby
require 'bundler/setup'

require 'cgi'
require 'sinatra'

# Serve files in lib without any modification.
set :public, File.join(File.dirname(__FILE__), 'lib')

# Serve templates from the same folder.
set :views, File.join(File.dirname(__FILE__), 'content')

helpers do
end

# Login HTML.
get('/') { erb :login }

# Chat HTML.
post '/chat' do
  @safe_name = CGI.escape params[:name]
  @safe_room = CGI.escape params[:room]
  erb :chat
end

# Chat JS.
get('/chat.js') { coffee :chat }
# Chat CSS.
get('/chat.css') { scss :chat }
