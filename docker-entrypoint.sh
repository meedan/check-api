#!/bin/bash

#since GITHUB_TOKEN environment variable is a json object, we need parse the value
#This function is here due to a limitation by "secrets manager"
function getParsedGithubToken(){
    
    
  echo $GITHUB_TOKEN | python -c 'import sys, json; print(json.load(sys.stdin)["GITHUB_TOKEN"])'
}
if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV, and APP must be in the environment. Exiting."
	exit 1
fi

$GITHUB_TOKEN_PARSED = $(getParsedGithubToken)

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN_PARSED}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done


# Wait for Elasticsearch
until curl --silent -XGET --fail http://elasticsearch:9200; do printf '.'; sleep 1; done

# Rake tasks
if [ "$RAILS_ENV" == "test" ]
then
  bundle exec rake db:drop
fi
bundle exec rake db:create
bundle exec rake db:migrate
export SECRET_KEY_BASE=$(bundle exec rake secret)
bundle exec rake lapis:api_keys:create_default

# App server
mkdir -p /app/tmp/pids
rm -f /app/tmp/pids/server-$RAILS_ENV.pid
if [ "$RAILS_ENV" == "test" ]
then
  bundle exec rails s -b 0.0.0.0 -p $SERVER_PORT -P /app/tmp/pids/server-$RAILS_ENV.pid
else
  puma="/app/tmp/puma-$RAILS_ENV.rb"
  cp config/puma.rb $puma
  echo "pidfile '/app/tmp/pids/server-$RAILS_ENV.pid'" >> $puma
  echo "port $SERVER_PORT" >> $puma
  bundle exec puma -C $puma
fi