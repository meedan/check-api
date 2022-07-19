#!/bin/bash

# start_background.sh

if [[ -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

# Create configuration from SSM and ENV settings
bash /opt/bin/create_config.sh

echo "starting static files server in background"
bundle exec ruby bin/static-files-server &

echo "starting sidekiq"
bundle exec sidekiq 
