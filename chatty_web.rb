#!/usr/bin/env ruby
require 'bundler'
Bundler.setup :default, :web

require 'cgi'
require 'sinatra'

class ChattyWeb < Sinatra::Application
  # Serve files in lib without any modification.
  set :public, File.join(File.dirname(__FILE__), 'public')
  
  # Serve templates from the same folder.
  set :views, File.dirname(__FILE__)
  
  helpers do
  end
  
  # Login HTML.
  get('/') { erb :"views/login" }
  
  # Chat HTML.
  post '/chat' do
    name = params[:name] && CGI.escape(params[:name])
    room = params[:room] && CGI.escape(params[:room])
    server = request.host
    port = 9494
    @chat_url = "ws://#{server}:#{port}/chat?room=#{room}&name=#{name}"
    erb :"views/chat"
  end
  
  # Chat JS.
  get('/application.js') do
    coffee Dir.glob('javascripts/**/*.coffee').sort.map { |f| File.read f }.join
  end
  
  # Chat CSS.
  get('/application.css') { scss :"stylesheets/application" }
end
