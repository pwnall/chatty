# Chatty

Chatty is a WebSockets-based chat server that persists conversations using
MongoDB.

## Pre-Requisites

### Debian

Get Ruby and Mongo.

```bash
sudo apt-get install ruby-full
sudo apt-get install mongodb
```

### Fedora

Get Ruby and Mongo.

```bash
sudo yum install ruby
sudo yum install mongdb mongodb-server
sudo systemctl enable mongod.service
sudo systemctl start mongod.service
```

### Common Setup

Install Bundler.

```bash
sudo gem update --system
sudo gem install bundler
```


## Setup and Upgrade

Install all the required gems.

```bash
bundle install
```

Create or update the database.

```bash
bundle exec server/db_schema.rb
```

Start up the web server.

```bash
bundle exec shotgun config.ru
nohup bundle exec unicorn config.ru > web.log &
```

Start up the chat server.

```bash
bundle exec server/boot.rb
nohup bundle exec server/boot.rb > server.log &
```
