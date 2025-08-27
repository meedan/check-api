# check-api
FROM ruby:3.0-slim
LABEL maintainer="sysops@meedan.com"

ENV DEPLOYUSER=checkdeploy \
    DEPLOYDIR=/app/current \
    RAILS_ENV=production \
    GITREPO=git@github.com:meedan/check-api.git \
    PRODUCT=check \
    APP=check-api \
    TERM=xterm \
    MIN_INSTANCES=4 \
    MAX_POOL_SIZE=4 \
    PERSIST_DIRS="uploads project_export memebuster team_dump" \
    MALLOC_ARENA_MAX=2
    # MALLOC_ARENA MAX is needed because of https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/
    # MIN_INSTANCES and MAX_POOL_SIZE control the pool size of passenger

# Set a UTF-8 capable locale
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

#
# USER CONFIG
#
RUN useradd ${DEPLOYUSER} -s /bin/bash -m

RUN apt-get update -qq && apt-get install -y curl

RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    ffmpegthumbnailer \
    ffmpeg \
    git \
    graphicsmagick \
    libidn11-dev \
    libpq-dev \
    libtag1-dev \
    lsof

# CMD and helper scripts
COPY --chown=root:root production/bin /opt/bin

#
# code deployment
#
RUN mkdir -p ${DEPLOYDIR} \
    && chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR} \
    && chmod -R 775 ${DEPLOYDIR} \
    && chmod g+s ${DEPLOYDIR}

WORKDIR ${DEPLOYDIR}

# install the gems
USER ${DEPLOYUSER}
# COPY's `--chown` directive cannot utilize environmental variables
# so we mimic `--chown=${DEPLOYUSER}:www-data`
COPY --chown=checkdeploy:www-data Gemfile ${DEPLOYDIR}/Gemfile
COPY --chown=checkdeploy:www-data Gemfile.lock ${DEPLOYDIR}/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc && gem install bundler -v "< 2.0"
RUN bundle config force_ruby_platform true
RUN bundle install --jobs 20 --retry 5 --deployment --without test development

# copy in the code
# COPY's `--chown` directive cannot utilize environmental variables
# so we mimic `--chown=${DEPLOYUSER}:www-data`
COPY --chown=checkdeploy:www-data . ${DEPLOYDIR}

USER ${DEPLOYUSER}

EXPOSE 3300
ENTRYPOINT ["/opt/bin/start.sh"]