#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log
SERVER_PORT=3300

cd /app/current

#since GITHUB_TOKEN environment variable is a json object, we need parse the value
#This function is here due to a limitation by "secrets manager"

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done

rm config/environment/initializers/errbit.rb

mkdir -p /app/current/tmp/pids
puma="/app/current/tmp/puma-${RAILS_ENV}.rb"
cp config/puma.rb $puma
cat << EOF >> $puma
pidfile '/app/current/tmp/pids/server-${RAILS_ENV}.pid'
environment '${RAILS_ENV}'
port ${SERVER_PORT} 
workers 3 
EOF
bundle exec puma -C $puma -t 8:32
