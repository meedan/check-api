#!/bin/bash

# Wait for Elasticsearch
# CURRENT_UID=$(id -u):$(id -g)
until curl --silent -XGET --fail http://elasticsearch:9200; do printf '.'; sleep 1; done

# Rake tasks
bin/rails db:environment:set RAILS_ENV=$RAILS_ENV || true
if [ "$RAILS_ENV" == "test" ]
then
  bundle exec rails db:drop
fi
bundle exec rails db:create
bundle exec rails db:migrate
export SECRET_KEY_BASE=$(bundle exec rails secret)
bundle exec rails lapis:api_keys:create_default

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
