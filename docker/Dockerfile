# Dockerfile
FROM seapy/rails-nginx-unicorn-pro:v1.0-ruby2.2.0-nginx1.6.0
MAINTAINER Meedan(hello@meedan.com)

# Add here other packages you need to install
RUN apt-get install vim -y

# Nginx config
ADD docker/nginx.conf /etc/nginx/sites-enabled/default

# Install Rails App
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN cd /app && bundle install --without development test
ADD . /app
RUN cd /app && bundle exec rake db:migrate
ADD docker/create-dev-key.rb /app/create-dev-key.rb
RUN cd /app && ruby create-dev-key.rb

WORKDIR /app

# Nginx port number
EXPOSE 80
