FROM ruby:3.0-slim
LABEL Meedan="sysops@meedan.com"

# the Rails stage can be overridden from the caller

# https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/

ENV RAILS_ENV=development \
    MALLOC_ARENA_MAX=2 \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    DEPLOYUSER=checkdeploy\
    DEPLOYDIR=/app

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

RUN useradd ${DEPLOYUSER} -s /bin/bash -m

# CMD and helper scripts
COPY --chown=${DEPLOYUSER} production/bin /opt/bin

RUN mkdir -p ${DEPLOYDIR} \
    && chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR} \
    && chmod -R 775 ${DEPLOYDIR} \
    && chmod g+s ${DEPLOYDIR}

# tx client
RUN curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash

# install our app
WORKDIR  ${DEPLOYDIR}

USER ${DEPLOYUSER}

# COPY --chown=${DEPLOYUSER} Gemfile ${DEPLOYDIR}/Gemfile
# COPY --chown=${DEPLOYUSER} Gemfile.lock ${DEPLOYDIR}/Gemfile.lock
COPY --chown=checkdeploy:www-data Gemfile ${DEPLOYDIR}/Gemfile
COPY --chown=checkdeploy:www-data Gemfile.lock ${DEPLOYDIR}/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc && gem install bundler
RUN bundle config force_ruby_platform true
RUN bundle install --jobs 20 --retry 5

COPY --chown=checkdeploy:www-data . ${DEPLOYDIR}

# remember the Rails console history
USER ${DEPLOYUSER}

RUN echo 'require "irb/ext/save-history"' > ~/.irbrc && \
    echo 'IRB.conf[:SAVE_HISTORY] = 200' >> ~/.irbrc && \
    echo 'IRB.conf[:HISTORY_FILE] = ENV["HOME"] + "/.irb-history"' >> ~/.irbrc


USER ${DEPLOYUSER}
# startup
RUN chmod +x ${DEPLOYDIR}/docker-entrypoint.sh
RUN chmod +x ${DEPLOYDIR}/docker-background.sh

EXPOSE 3000
CMD ["/app/docker-entrypoint.sh"]