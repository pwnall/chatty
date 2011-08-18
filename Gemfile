source 'http://rubygems.org'

gem 'json', '>= 1.5.0', :platforms => [:ruby_18]
gem 'nokogiri', '>= 1.5.0'

group :chat do
  gem 'em-mongo', '>= 0.4.0'
  gem 'em-websocket', '>= 0.3.1',
      :git => 'git://github.com/igrigorik/em-websocket.git'
  gem 'eventmachine', '>= 0.12.10'
end

group :chat_db do
  gem 'mongo', '>= 1.3.1'
  gem 'bson_ext', '>= 1.3.1'
end

group :web do
  gem 'sinatra', '>= 1.0.0'
  gem 'shotgun', '>= 0.9'
  gem 'unicorn', '>= 4.0.0'

  gem 'coffee-script', '>= 2.2'
  gem 'sass', '>= 3.1.0'
  gem 'therubyracer', '>= 0.9.2'
end
