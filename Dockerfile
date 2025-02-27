FROM ruby:3.0-slim
LABEL Meedan="sysops@meedan.com"

# Set environment variables
ENV RAILS_ENV=development \
    MALLOC_ARENA_MAX=2 \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    DEPLOYUSER=checkdeploy 

# Install necessary dependencies
RUN apt-get update -qq && apt-get install -y curl

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
    lsof \
    curl 

# tx client
RUN curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash

RUN useradd -m -s /bin/bash $DEPLOYUSER && \
    mkdir -p /opt/bin /app && \
    chown -R $DEPLOYUSER:$DEPLOYUSER /opt/bin /app

USER $DEPLOYUSER

COPY --chown=root:root production/bin /opt/bin

WORKDIR /app

# Copy Gemfiles and install dependencies
COPY --chown=${DEPLOYUSER}:${DEPLOYUSER} Gemfile /app/Gemfile
COPY --chown=${DEPLOYUSER}:${DEPLOYUSER} Gemfile.lock /app/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc && gem install bundler
RUN bundle config force_ruby_platform true 
RUN bundle install --jobs 20 --retry 5

RUN chown -R $DEPLOYUSER:$DEPLOYUSER .
# Copy application files
COPY --chown=${DEPLOYUSER}:${DEPLOYUSER} . .

# remember the Rails console history
RUN echo 'require "irb/ext/save-history"' > ~/.irbrc && \
    echo 'IRB.conf[:SAVE_HISTORY] = 200' >> ~/.irbrc && \
    echo 'IRB.conf[:HISTORY_FILE] = ENV["HOME"] + "/.irb-history"' >> ~/.irbrc

RUN chmod a+w /app/docker-entrypoint.sh /app/docker-background.sh
EXPOSE 3000
CMD ["/app/docker-entrypoint.sh"]
