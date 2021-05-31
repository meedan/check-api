FROM ruby:2.4-slim
MAINTAINER Meedan <sysops@meedan.com>

# the Rails stage can be overridden from the caller
ENV RAILS_ENV development

# https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/
ENV MALLOC_ARENA_MAX 2

# Set a UTF-8 capabable locale
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8

RUN apt-get update -qq && apt-get install -y --no-install-recommends curl

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

# sqlite3, lz4: for check:data:export_team task
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    ffmpegthumbnailer \
    git \
    graphicsmagick \
    inotify-tools \
    libidn11-dev \
    libpq-dev \
    libsqlite3-dev \
    libtag1-dev \
    lsof \
    lz4 \
    nodejs \
    python-pip \
    rename \
    sqlite3

RUN python -m pip install -U setuptools wheel

# install our app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc \
    gem install bundler -v "< 2.0" \
    && bundle install --jobs 20 --retry 5
COPY . /app

# remember the Rails console history
RUN echo 'require "irb/ext/save-history"' > ~/.irbrc && \
    echo 'IRB.conf[:SAVE_HISTORY] = 200' >> ~/.irbrc && \
    echo 'IRB.conf[:HISTORY_FILE] = ENV["HOME"] + "/.irb-history"' >> ~/.irbrc

# startup
RUN chmod +x /app/docker-entrypoint.sh
RUN chmod +x /app/docker-background.sh
EXPOSE 3000
CMD ["/app/docker-entrypoint.sh"]
