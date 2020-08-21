#!/bin/bash

# run the command using the $DEPLOYUSER

set -e

DEPLOY_ENV=$1

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV  must be in the environment. Exiting."
	exit 1
fi

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done

command=$@

echo "Running Command ($command)"
# su to DEPLOYUSER and be sure to exit with the proper exit both inside and outside the migration
$($command)
STATUS=$?

echo "migrations completed with exit $STATUS"

exit $STATUS
