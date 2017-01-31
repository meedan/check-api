#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/current/log/${RAILS_ENV}.log
UPLOADS=${DEPLOYDIR}/shared/files/uploads

function config_replace() {
    # sed -i "s/ddRAILS_ENVdd/${RAILS_ENV}/g" /etc/nginx/sites-available/${APP}
    VAR=$1
    VAL=$2
    FILE=$3
    #    echo evaluating $VAR $VAL $FILE;
    if grep --quiet "dd${VAR}dd" $FILE; then
	echo "setting $VAR to $VAL in $FILE"
	CMD="s/dd${VAR}dd/${VAL}/g"
	sed -i'.bak' -e ${CMD} ${FILE}
    fi
}

# sed in environmental variables
for ENV in $( env | cut -d= -f1); do
    config_replace "$ENV" "${!ENV}" /etc/nginx/sites-available/${APP}
done


echo "setting permissions for ${LOGFILE}"
touch ${LOGFILE}
chown ${DEPLOYUSER}:www-data ${LOGFILE}
chmod 775 ${LOGFILE}

echo "setting permissions for ${UPLOADS}"
chown -R ${DEPLOYUSER}:www-data ${UPLOADS}
find ${UPLOADS} -type d -exec chmod 2777 {} \; # set the sticky bit on directories to preserve permissions
find ${UPLOADS} -type f -exec chmod 0664 {} \; # files are 664

echo "tailing ${LOGFILE}"
tail -f $LOGFILE &

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
