#!/bin/bash

# start_background.sh


LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log

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
su ${DEPLOYUSER} -c "mkdir -p /app/current/tmp"

echo "starting static files server"
su ${DEPLOYUSER} -c "bundle exec ruby bin/static-files-server &"

echo "starting sidekiq"
su ${DEPLOYUSER} -c "bundle exec sidekiq -L ${LOGFILE} | tee ${LOGFILE}"
