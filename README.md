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

Start up Chatty in development mode.

```bash
foreman start
```


## Production Setup

After following the common steps above, go through the additional instructions
below.

### SSL

Production installations should use SSL to protect users' privacy.
[StartSSL](https://www.startssl.com/?app=1) provides free SSL certificates.

The
command below generates a CSR for use with any SSL provider, in
`ssl/chatty.csr`.

```bash
openssl req -new -newkey rsa:2048 -sha256 -nodes -keyout ssl/chatty.pem -out ssl/chatty.csr
```

If you use StartSSL, open `ssl/chatty.csr` in a text editor and copy-paste its
contents in the certificate request form.

The certificate chain from the SSL provider should be saved in `ssl/chatty.crt`
in PEM format.

If you use StartSSL, use the following commands to put together a chain.

```bash
vim ssl/chatty.cer  # Paste the OpenSSL certificate.
curl https://www.startssl.com/certs/ca.pem > ssl/ca.pem
curl https://www.startssl.com/certs/sub.class1.server.ca.pem > ssl/ca2.pem
cat ssl/chatty.cer ssl/ca.pem ssl/ca2.pem > ssl/chatty.crt
rm ssl/ca.pem ssl/ca2.pem ssl/chatty.crt
```

If you use git for deployment, use the commands below to add your SSL
certificates to a (protected) `prod` branch, and always rebase against `master`
instead of merging.

```bash
git checkout -b prod
git add -f ssl/chatty.crt ssl/chatty.pem
git commit -m "Production SSL certificates."
```

Chatty's application server is not well-suited to be exposed to the outside
world and does not support SSL. Configure [nginx](http://nginx.org) as a
reverse proxy, and point it to the Chatty SSL certificates. Below is a sample
nginx configuration.

```
upstream chatty {
  server 127.0.0.1:12300;
}
server {
  listen 443;
  charset utf-8;

  ssl on;
  ssl_certificate /home/chatty_user/chatty/ssl/chatty.crt;
  ssl_certificate_key /home/chatty_user/chatty/ssl/chatty.pem;

  server_name chatty.server.com;
  root /home/chatty_user/chatty/public;
  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_set_header Host $host;
    proxy_redirect off;
    proxy_connect_timeout 2;
    proxy_read_timeout 86400;
    if (!-f $request_filename) {
      proxy_pass http://chatty;
      break;
    }
  }
}
```

To test your SSL and nginx configuration on your machine, add your server's
DNS name to `/etc/hosts` on your development machine.

```
127.0.0.1 chat.pwnb.us
```

### Service

Chatty should be ran as a service in production, so it survives server reboots.

```bash
# Ubuntu / Debian
foreman export upstart /etc/init --procfile Procfile.prod --env prod.env --user $USER --port 12300
# Fedora / RedHat
foreman export systemd /etc/systemd/system --procfile Procfile.prod --env prod.env --user $USER --port 12300
```


## Credits

The Flash shim that provides WebSocket support to Internet Explorer was sourced
from [the web-socket-js project](https://github.com/gimite/web-socket-js).

JavaScript color processing is done by the
[color.js library](https://github.com/harthur/color).

The icons are provided by
[FontAwesome](http://fortawesome.github.com/Font-Awesome/).

The [Source Sans Pro](http://www.google.com/webfonts/specimen/Source%20Sans%20Pro)
font was chosen with the help of the
[Google Web Fonts Families demo](http://somadesign.ca/demos/better-google-fonts/).
