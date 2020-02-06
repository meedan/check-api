#!/bin/bash

# start_background.sh

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done

LOGFILE=${DEPLOYDIR}/log/sidekiq.log

echo "setting permissions for ${LOGFILE}"
touch ${LOGFILE}
chown ${DEPLOYUSER}:www-data ${LOGFILE}
chmod 775 ${LOGFILE}

echo PERSIST_DIRS $PERSIST_DIRS
for d in ${PERSIST_DIRS}; do
    d=/app/shared/files/${d}
    if [ ! -e "${d}" ]; then
        echo "creating directory ${d}"
        mkdir -p ${d}
    fi
done

echo "create the temporary directory"
mkdir -p /app/current/tmp

echo "starting static files server"
bundle exec ruby bin/static-files-server &

echo "starting sidekiq"
bundle exec sidekiq -L ${LOGFILE} &

tail -f ${LOGFILE}
