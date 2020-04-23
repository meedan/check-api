FROM ruby:2.4-slim
MAINTAINER Meedan <sysops@meedan.com>

# the Rails stage can be overridden from the caller
ENV RAILS_ENV development

# https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/
ENV MALLOC_ARENA_MAX 2

RUN apt-get update -qq && apt-get install -y --no-install-recommends curl

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

RUN apt-get update && apt-get install --no-install-recommends -y nodejs git build-essential libpq-dev sqlite3 libsqlite3-dev graphicsmagick inotify-tools \
    ffmpegthumbnailer fontconfig libfontconfig fonts-beng fonts-deva fonts-samyak-gujr fonts-mlym fonts-taml fonts-smc fonts-taml fonts-telu

# phantomjs
RUN curl -sL https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -xjf - phantomjs-2.1.1-linux-x86_64/bin/phantomjs && \
    mv phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin/ && \
    rm -rf phantomjs*
ENV OPENSSL_CONF /etc/ssl/

# install our app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc \
    gem install bundler -v "< 2.0" \
    && bundle install --jobs 20 --retry 5
COPY . /app

# startup
RUN chmod +x /app/docker-entrypoint.sh
RUN chmod +x /app/docker-background.sh
EXPOSE 3000
CMD ["/app/docker-entrypoint.sh"]
