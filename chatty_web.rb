#!/usr/bin/env ruby
require 'bundler'
Bundler.setup :default, :web

require 'cgi'
require 'compass'
require 'sinatra'

class ChattyWeb < Sinatra::Application
  # Serve files in lib without any modification.
  set :public_folder, File.join(File.dirname(__FILE__), 'public')

  # Serve templates from the same folder.
  set :views, File.dirname(__FILE__)

  helpers do
  end

  # Login HTML.
  get '/' do
    erb :"views/login"
  end

  # Requested when Chrome restarts with a chat window open.
  get '/chat' do
    redirect '/'
  end

  # Chat HTML.
  post '/chat' do
    name = params[:name] && CGI.escape(params[:name].strip)
    room = params[:room] && CGI.escape(params[:room].strip)
    name_color = params[:name_color] ? params[:name_color].strip : '000000'
    server = request.host
    port = ENV['PORT'] ? ENV['PORT'].to_i + 100 : 9494
    @chat_url = "ws://#{server}:#{port}/chat?room=#{room}&name=#{name}&" +
                "name_color=#{name_color}"
    erb :"views/chat"
  end

  # Chat JS.
  get('/application.js') do
    coffee Dir.glob('javascripts/**/*.coffee').sort.map { |f| File.read f }.join
  end

  # Chat CSS.
  get('/application.css') do
    scss :"stylesheets/application", Compass.sass_engine_options
  end
end
