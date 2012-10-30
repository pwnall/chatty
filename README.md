# Chatty

Chatty is a WebSockets-based chat server that persists conversations using
MongoDB.

## Pre-Requisites

### Debian

Get Ruby and Mongo.

```bash
sudo apt-get install ruby-full
sudo apt-get install mongodb mongodb-server
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
foreman start
```

For production use, create a service.

```bash
foreman export systemd /etc/systemd/system --procfile Procfile.prod --user $USER
foreman export upstart /etc/init --procfile Procfile.prod --user $USER
```


## Credits

The Flash shim that provides WebSocket support to Internet Explorer was sourced
from [the web-socket-js project](https://github.com/gimite/web-socket-js).
