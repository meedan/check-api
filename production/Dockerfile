# checkdesk-api

FROM meedan/ruby
MAINTAINER sysops@meedan.com

#
# SYSTEM CONFIG
#
ENV DEPLOYUSER cddeploy
ENV DEPLOYDIR /app
ENV RAILS_ENV production
ENV GITREPO git@github.com:meedan/checkdesk-api.git
ENV APP checkdesk-api

#
# DEPENDENCIES
#
RUN apt-get install -y imagemagick

#
# APP CONFIG
#

# nginx for checkdesk-api
COPY production/nginx.conf /etc/nginx/sites-available/${APP}
RUN ln -s /etc/nginx/sites-available/${APP} /etc/nginx/sites-enabled/${APP}
RUN rm /etc/nginx/sites-enabled/default


#
# USER CONFIG
#

RUN useradd ${DEPLOYUSER} -s /bin/bash -m
RUN chown -R ${DEPLOYUSER}:${DEPLOYUSER} /home/${DEPLOYUSER}

#
# code deployment
#
RUN mkdir -p ${DEPLOYDIR}/latest \
    && chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR} \
    && chmod 775 ${DEPLOYDIR} \
    && chmod g+s ${DEPLOYDIR}/latest

WORKDIR ${DEPLOYDIR}

# install the gems
COPY ./Gemfile ./latest/Gemfile
COPY ./Gemfile.lock ./latest/Gemfile.lock
USER ${DEPLOYUSER}
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc \
    && cd ./latest \
    && bundle install --deployment --without test development

USER root

# deployment scripts
COPY production/bin /opt/bin
RUN chmod 755 /opt/bin/*

# copy in the code
COPY . ./latest
RUN chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR}
USER ${DEPLOYUSER}


# link config files
RUN /opt/bin/find_and_link_config_files.sh ${DEPLOYDIR}/latest
# link to uploads
RUN mkdir -p ${DEPLOYDIR}/shared/files/uploads \
    && ln -s ${DEPLOYDIR}/shared/files/uploads ${DEPLOYDIR}/latest/public/uploads

RUN mv ./latest ./${APP}-$(date -I) && ln -s ./${APP}-$(date -I) ./current

#
# RUNTIME ELEMENTS
# expose, cmd

USER root

WORKDIR ${DEPLOYDIR}/current

CMD ["/opt/bin/start.sh"]
