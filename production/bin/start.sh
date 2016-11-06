#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/current/log/${RAILS_ENV}.log
UPLOADS=${DEPLOYDIR}/shared/files/uploads
NGINXLOG=/var/log/nginx/error.log


echo "setting permissions for ${LOGFILE}"
touch ${LOGFILE}
chown ${DEPLOYUSER}:www-data ${LOGFILE}
chmod 775 ${LOGFILE}

if [ ! -e ${UPLOADS} ]; then
	mkdir -p ${UPLOADS}
fi

echo "setting permissions for ${UPLOADS}"
chown -R ${DEPLOYUSER}:www-data ${UPLOADS}
find ${UPLOADS} -type d -exec chmod 2777 {} \; # set the sticky bit on directories to preserve permissions
find ${UPLOADS} -type f -exec chmod 0664 {} \; # files are 664

echo "tailing ${LOGFILE}"
tail -f $LOGFILE &
echo "tailing ${NGINXLOG}"
tail -f $NGINXLOG &

# should only run migrations on ${PRIMARY} nodes, perhaps in an out-of-band process during major multi-node deployments
if [ -n "${PRIMARY}" ]; then
	echo "running migrations"
	su ${DEPLOYUSER} -c "bundle exec rake db:migrate"
fi

echo "starting sidekiq"
su ${DEPLOYUSER} -c "bundle exec sidekiq -L log/sidekiq.log -d"

echo "starting nginx"
echo "--STARTUP FINISHED--"
nginx
