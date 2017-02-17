#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/current/log/${RAILS_ENV}.log
UPLOADS=${DEPLOYDIR}/shared/files/uploads

echo "setting permissions for ${LOGFILE}"
touch ${LOGFILE}
chown ${DEPLOYUSER}:www-data ${LOGFILE}
chmod 775 ${LOGFILE}

echo "tailing ${LOGFILE}"
tail -f $LOGFILE &
TAILPID=$!

echo "running migrations"
su ${DEPLOYUSER} -c "bundle exec rake db:migrate"

echo "migrations complete"
kill $TAILPID
