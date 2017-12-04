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

if [ "$RAILS_ENV" == "test" ]; then
    # comment out the include
    sed -i'.bak' -e 's|include /etc/nginx/sites-available/test_404.conf|# include /etc/nginx/sites-available/test_404.conf|g' /etc/nginx/sites-available/${APP}
fi

echo "setting permissions for ${LOGFILE}"
touch ${LOGFILE}
chown ${DEPLOYUSER}:www-data ${LOGFILE}
chmod 775 ${LOGFILE}

echo "setting permissions for ${UPLOADS}"
chown -R ${DEPLOYUSER}:www-data ${UPLOADS}
find ${UPLOADS} -type d -exec chmod 2777 {} \; # set the sticky bit on directories to preserve permissions
find ${UPLOADS} -type f -exec chmod 0664 {} \; # files are 664


# should only run migrations on ${PRIMARY} nodes, perhaps in an out-of-band process during major multi-node deployments
# for live environments PRIMARY is *not* set and run_migration.sh is called in a separate process
if [ -n "${PRIMARY}" ]; then
    /opt/bin/run_migration.sh
fi

bundle exec rake assets:precompile

echo "tailing ${LOGFILE}"
tail -f $LOGFILE &

echo "starting google chrome headless"
LC_ALL=C google-chrome --headless --hide-scrollbars --remote-debugging-port=9333 --disable-gpu --ignore-certificate-errors &
sleep 3

echo "starting sidekiq"
su ${DEPLOYUSER} -c "bundle exec sidekiq -L log/sidekiq.log -d"

echo "starting nginx"
echo "--STARTUP FINISHED--"
nginx
