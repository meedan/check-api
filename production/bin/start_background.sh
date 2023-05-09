#!/bin/bash

# start_background.sh

if [[ -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

# Create configuration from SSM and ENV settings
bash /opt/bin/create_configs.sh

# Setup puma server
mkdir -p ${PWD}/tmp/pids
mkdir -p ${PWD}/log
puma="${PWD}/tmp/puma-${RAILS_ENV}.rb"
cp config/puma.rb ${puma}
cat << EOF >> ${puma}
pidfile '/app/current/tmp/pids/server-${RAILS_ENV}.pid'
environment '${RAILS_ENV}'
workers 2
worker_timeout 120
EOF

echo "starting sidekiq"
bundle exec sidekiq
