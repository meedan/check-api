# Dockerfile
FROM seapy/rails-nginx-unicorn-pro:v1.1-ruby2.3.0-nginx1.8.1
MAINTAINER Meedan(hello@meedan.com)

# Add here other packages you need to install
RUN apt-get install vim -y

# Nginx config
COPY docker/nginx.conf /etc/nginx/sites-enabled/default

# Install Rails App
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN cd /app && bundle install --without development test
COPY . /app
RUN cd /app && bundle exec rake db:migrate
COPY docker/create-dev-key.rb /app/create-dev-key.rb
RUN cd /app && ruby create-dev-key.rb

WORKDIR /app

# Nginx port number
EXPOSE 80
