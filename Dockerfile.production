# check-api
FROM meedan/ruby
MAINTAINER sysops@meedan.com

ENV DEPLOYUSER=checkdeploy \
    DEPLOYDIR=/app/current \
    RAILS_ENV=production \
    GITREPO=git@github.com:meedan/check-api.git \
    PRODUCT=check \
    APP=check-api \
    TERM=xterm \
    MIN_INSTANCES=4 \
    MAX_POOL_SIZE=12 \
    PERSIST_DIRS="uploads project_export memebuster" \
    MALLOC_ARENA_MAX=2
    # MALLOC_ARENA MAX is needed because of https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/
    # MIN_INSTANCES and MAX_POOL_SIZE control the pool size of passenger

#
# USER CONFIG
#
RUN useradd ${DEPLOYUSER} -s /bin/bash -m

#
# SYSTEM CONFIG
#

# dependencies
RUN apt-get update -qq && apt-get install -y fontconfig libfontconfig ttf-devanagari-fonts ttf-bengali-fonts ttf-gujarati-fonts ttf-telugu-fonts ttf-tamil-fonts ttf-malayalam-fonts

# phantomjs
RUN wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    tar -vxjf phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    mv phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin/

# nginx for check-api
COPY --chown=checkdeploy:www-data production/config/nginx/app.conf /etc/nginx/sites-available/${APP}
COPY --chown=checkdeploy:www-data production/config/nginx/test_404.conf /etc/nginx/sites-available/test_404.conf
RUN sed -i "s/ddDEPLOYUSERdd/checkdeploy/g" /etc/nginx/sites-available/${APP} \
    && ln -s /etc/nginx/sites-available/${APP} /etc/nginx/sites-enabled/${APP} \
    && rm /etc/nginx/sites-enabled/default

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
COPY --chown=checkdeploy:www-data ./Gemfile ${DEPLOYDIR}/Gemfile
COPY --chown=checkdeploy:www-data ./Gemfile.lock ${DEPLOYDIR}/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc \
    && bundle install  --jobs 20 --retry 5 --deployment --without test development

# copy in the code
# COPY's `--chown` directive cannot utilize environmental variables
# so we mimic `--chown=${DEPLOYUSER}:www-data`
COPY --chown=checkdeploy:www-data . ${DEPLOYDIR}

USER root

# link config files
RUN /opt/bin/find_and_link_config_files.sh ${DEPLOYDIR}
# persist these directories
RUN for d in ${PERSIST_DIRS}; do mkdir -p /app/shared/files/${d} \
    && ln -s /app/shared/files/${d} ${DEPLOYDIR}/public/${d}; done

RUN ln -s ${DEPLOYDIR} /app/${APP}-$(date -I)


#
# RUNTIME ELEMENTS
# expose, cmd

EXPOSE 3300

WORKDIR ${DEPLOYDIR}
CMD ["/opt/bin/start.sh"]
