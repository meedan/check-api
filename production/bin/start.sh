#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log
SERVER_PORT=3300

if [[ -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

# Move default configs into place.
# For most environments, these settings are overridden in ENV set from SSM.
(
  cd config
  ln clean_db.yml.example clean_db.yml
  ln config.yml.example config.yml
  ln credentials.json.example credentials.json
  ln database.yml.example database.yml
  ln sidekiq.yml.example sidekiq.yml

  # For apollo engine proxy config, we use ENV set via SSM:
  WORKTMP=$(mktemp)
  if [[ -z ${apollo-proxy-config+x} ]]; then
    echo "Error: missing apollo-proxy-config ENV setting. Using defaults."
    ln apollo-engine-proxy.json.example apollo-engine-proxy.json
  fi
  echo $apollo-proxy-config | python -m base64 -d > $WORKTMP
  if (( $? != 0 )); then
    echo "Error: could not decode configured ENV var: $apollo-proxy-config . Skipping apollo config."
    rm apollo-engine-proxy.json
  else
    echo "Using decoded configuration from ENV var: $apollo-proxy-config."
    mv $WORKTMP apollo-engine-proxy.json
    sha1sum apollo-engine-proxy.json
  fi
)

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
