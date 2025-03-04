FROM ruby:3.0-slim
LABEL Meedan="sysops@meedan.com"

# the Rails stage can be overridden from the caller

ENV RAILS_ENV=development

# https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/
ENV MALLOC_ARENA_MAX=2

# Set a UTF-8 capabable locale
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

# Setup a user account
ENV DEPLOYUSER=checkdeploy
RUN useradd ${DEPLOYUSER} -s /bin/bash -m


RUN apt-get update -qq && apt-get install -y --no-install-recommends curl

RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    ffmpegthumbnailer \
    ffmpeg \
    git \
    graphicsmagick \
    libidn11-dev \
    inotify-tools \
    libpq-dev \
    libtag1-dev \
    lsof

# CMD and helper scripts
COPY --chown=root:root production/bin /opt/bin

# tx client
RUN curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash

# install our app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc && gem install bundler
RUN bundle config force_ruby_platform true
RUN bundle install --jobs 20 --retry 5

# Copy the application code and change ownership to the non-root user
COPY --chown=${DEPLOYUSER}:${DEPLOYUSER} . /app

# remember the Rails console history
RUN echo 'require "irb/ext/save-history"' > ~/.irbrc && \
    echo 'IRB.conf[:SAVE_HISTORY] = 200' >> ~/.irbrc && \
    echo 'IRB.conf[:HISTORY_FILE] = ENV["HOME"] + "/.irb-history"' >> ~/.irbrc

# startup
RUN chmod +x /app/docker-entrypoint.sh
RUN chmod +x /app/docker-background.sh

# Switch to the non-root user
USER ${DEPLOYUSER}

EXPOSE 3000
CMD ["/app/docker-entrypoint.sh"]
