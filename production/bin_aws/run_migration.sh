#!/bin/bash

# run the migrations using the $DEPLOYUSER

set -e

#since GITHUB_TOKEN environment variable is a json object, we need parse the value
#This function is here due to a limitation by "secrets manager"
function getParsedGithubToken(){
    
  return echo $GITHUB_TOKEN | jq -r .GITHUB_TOKEN

}

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

$GITHUB_TOKEN_PARSED = $(getParsedGithubToken)

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN_PARSED}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done


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
