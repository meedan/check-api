FROM ruby:3.0-slim
LABEL Meedan="sysops@meedan.com"

# Setup a user account
ENV DEPLOYUSER=checkdeploy \
    DEPLOYDIR=/app \
    RAILS_ENV=development \
    MALLOC_ARENA_MAX=2 \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    APP=check-api

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

# tx client
RUN curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash

# CMD and helper scripts
COPY --chown=root:root production/bin /opt/bin

RUN mkdir -p ${DEPLOYDIR} \
    && chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR} \
    && chmod -R 775 ${DEPLOYDIR} \
    && chmod g+s ${DEPLOYDIR}


WORKDIR ${DEPLOYDIR}

USER ${DEPLOYUSER}
# install our app
COPY --chown=checkdeploy:www-data Gemfile ${DEPLOYDIR}/Gemfile
COPY --chown=checkdeploy:www-data Gemfile.lock ${DEPLOYDIR}/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc && gem install bundler -v "< 2.0"
RUN bundle config force_ruby_platform true
RUN bundle install --jobs 20 --retry 5 


# remember the Rails console history
RUN echo 'require "irb/ext/save-history"' > ~/.irbrc && \
    echo 'IRB.conf[:SAVE_HISTORY] = 200' >> ~/.irbrc && \
    echo 'IRB.conf[:HISTORY_FILE] = ENV["HOME"] + "/.irb-history"' >> ~/.irbrc

# COPY --chown=checkdeploy:www-data . ${DEPLOYDIR}

COPY . /app
USER ${DEPLOYUSER}
# startup
RUN chmod +x ${DEPLOYDIR}/docker-entrypoint.sh
RUN chmod +x ${DEPLOYDIR}/docker-background.sh
EXPOSE 3000
CMD ["/app/docker-entrypoint.sh"]