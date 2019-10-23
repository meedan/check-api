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

echo "starting sidekiq"
su ${DEPLOYUSER} -c "bundle exec sidekiq -L ${LOGFILE} | tee ${LOGFILE}"
