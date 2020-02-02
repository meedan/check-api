#!/bin/bash

# run the migrations using the $DEPLOYUSER

set -e

DEPLOY_ENV=$1

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV  must be in the environment. Exiting."
	exit 1
fi

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done

echo "running migrations"
# su to DEPLOYUSER and be sure to exit with the proper exit both inside and outside the migration
su ${DEPLOYUSER} -c 'bundle exec rake db:migrate; exit $?'
STATUS=$?

echo "migrations completed with exit $STATUS"

exit $STATUS
