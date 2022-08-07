#!/bin/bash

# start.sh
# the Dockerfile CMD

# generate configs with group and world read permissions.
umask 022

LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log
SERVER_PORT=3300

if [[ -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

# Create configuration files based on SSM and ENV settings.
bash /opt/bin/create_configs.sh

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

echo "Running API server with Puma at $puma and logile $LOGFILE"
bundle exec puma -C ${puma} -t 4:32 -p 3300 -p 8000
