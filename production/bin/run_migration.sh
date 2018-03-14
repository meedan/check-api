#!/bin/bash

# run the migrations using the $DEPLOYUSER

set -e

LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log
UPLOADS=/app/shared/files/uploads

echo "setting permissions for ${LOGFILE}"
touch ${LOGFILE}
chown ${DEPLOYUSER}:www-data ${LOGFILE}
chmod 775 ${LOGFILE}

echo "tailing ${LOGFILE}"
tail -f $LOGFILE &
TAILPID=$!

echo "running migrations"
# su to DEPLOYUSER and be sure to exit with the proper exit both inside and outside the migration
su ${DEPLOYUSER} -c 'bundle exec rake db:migrate; exit $?'
STATUS=$?

echo "migrations completed with exit $STATUS"
kill $TAILPID

exit $STATUS
