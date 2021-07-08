#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log
SERVER_PORT=3300

if [[ -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

/app/current/vendor/bundle/ruby/2.4.0/gems/apollo-tracing-1.5.0/bin/engineproxy_linux_amd64 --config config/apollo-engine-proxy.json &

mkdir -p ${PWD}/tmp/pids
puma="${PWD}/tmp/puma-${RAILS_ENV}.rb"
cp config/puma.rb ${puma}
cat << EOF >> ${puma}
pidfile '/app/current/tmp/pids/server-${RAILS_ENV}.pid'
environment '${RAILS_ENV}'
port ${SERVER_PORT} 
workers 2 
worker_timeout 120
EOF

bundle exec puma -C ${puma} -t 4:32
