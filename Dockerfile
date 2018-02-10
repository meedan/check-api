FROM meedan/ruby
MAINTAINER Meedan <sysops@meedan.com>

# the Rails stage can be overridden from the caller
ENV RAILS_ENV development

# install dependencies
RUN apt-get update -qq && apt-get install -y libpq-dev imagemagick redis-server autoconf automake libtool libltdl-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*

# install stuff needed to take screenshots
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' && \
    apt-get update && apt-get install -y google-chrome-stable
RUN curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash - && apt-get install -y nodejs && \
    npm install chrome-remote-interface minimist

# install our app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc \
    gem install bundler \
    && bundle install --jobs 20 --retry 5
COPY . /app

# startup
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["tini", "--"]
CMD ["/docker-entrypoint.sh"]
