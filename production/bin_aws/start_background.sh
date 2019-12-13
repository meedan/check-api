#!/bin/bash

# start_background.sh

#since GITHUB_TOKEN environment variable is a json object, we need parse the value
#This function is here due to a limitation by "secrets manager"
function getParsedGithubToken(){
    
  return echo $GITHUB_TOKEN | jq -r .GITHUB_TOKEN

}

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

GITHUB_TOKEN_PARSED = $(getParsedGithubToken)

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN_PARSED}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done


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
