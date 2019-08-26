#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log

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

echo PERSIST_DIRS $PERSIST_DIRS
for d in ${PERSIST_DIRS}; do
    d=/app/shared/files/${d}
    if [ ! -e "${d}" ]; then
        echo "creating directory ${d}"
        mkdir -p ${d}
    fi

#    echo "setting permissions for ${d}"
#    chown -R ${DEPLOYUSER}:www-data ${d}
#    find ${d} -type d -exec chmod 2777 {} \; # set the sticky bit on directories to preserve permissions
#    find ${d} -type f -exec chmod 0664 {} \; # files are 664
done


# should only run migrations on ${PRIMARY} nodes, perhaps in an out-of-band process during major multi-node deployments
# for live environments PRIMARY is *not* set and run_migration.sh is called in a separate process
if [ -n "${PRIMARY}" ]; then
    /opt/bin/run_migration.sh
fi

# compile assets in the background, particularly the admin interface
su ${DEPLOYUSER} -c "nice bundle exec rake assets:precompile" &

echo "tailing ${LOGFILE}"
tail -f $LOGFILE &

echo "starting sidekiq"
# su ${DEPLOYUSER} -c "bundle exec sidekiq -L log/sidekiq.log -d"
su ${DEPLOYUSER} -c "bundle exec sidekiq &"

echo "compiling assets"
su ${DEPLOYUSER} -c "bundle exec rake assets:precompile"

echo "starting nginx"
echo "--STARTUP FINISHED--"
nginx
