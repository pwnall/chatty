require 'cgi'
require 'compass'
require 'sinatra'

class Chatty < Sinatra::Application
  # Serve files in public/ without any modification.
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :static_cache_control, [:public, :must_revalidate, max_age: 3600]

  # Serve templates from the same folder.
  set :views, File.dirname(__FILE__)

  # Compass.
  set :scss, Compass.sass_engine_options

  helpers do
    # Sets cache headers in develpment, but not in production.
    def static_cache
      if self.class.production?
        cache_control :public, :must_revalidate, :max_age => 3600
      else
        cache_control :no_cache, :no_store
      end
    end
  end

  # Login HTML.
  get '/' do
    static_cache
    erb :"views/login"
  end

  # Requested when Chrome restarts with a chat window open.
  get '/chat' do
    static_cache
    redirect '/'
  end

  # Chat HTML.
  post '/chat' do
    name = params[:name] && CGI.escape(params[:name].strip)
    room = params[:room] && CGI.escape(params[:room].strip)
    name_color = params[:name_color] ? params[:name_color].strip : '000000'
    server = request.host
    port = ENV['PORT'] ? ENV['PORT'].to_i + 100 : 9494
    protocol = request.ssl? ? 'wss' : 'ws'
    @chat_url = "#{protocol}://#{server}:#{port}/chat?room=#{room}&" +
                "name=#{name}&name_color=#{name_color}"

    cache_control :no_cache, :no_store
    erb :"views/chat"
  end

  # Chat JS.
  get('/application.js') do
    static_cache
    coffee Dir.glob('web/javascripts/**/*.coffee').sort.map { |f| File.read f }.
           join("\n")
  end

  # Chat CSS.
  get('/application.css') do
    static_cache
    scss :"stylesheets/application"
  end

end
