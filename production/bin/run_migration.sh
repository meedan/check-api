#!/bin/bash

# run the migrations using the $DEPLOYUSER

set -e

DEPLOY_ENV=$1

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV  must be in the environment. Exiting."
	exit 1
fi

# Create configuration files based on SSM and ENV settings.
bash /opt/bin/create_configs.sh

echo "running migrations"
# su to DEPLOYUSER and be sure to exit with the proper exit both inside and outside the migration
bundle exec rake db:migrate
STATUS=$?

echo "migrations completed with exit $STATUS"

exit $STATUS
