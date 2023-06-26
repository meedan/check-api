#!/bin/bash

# Wait for Elasticsearch
until curl --silent -XGET --fail http://elasticsearch:9200; do printf '.'; sleep 1; done

bundle exec rails db:create db:migrate db:test:prepare
export SECRET_KEY_BASE=$(bundle exec rails secret)
bundle exec rails lapis:api_keys:create_default

# App server
mkdir -p /app/tmp/pids
rm -f /app/tmp/pids/server-$RAILS_ENV.pid
if [ "$RAILS_ENV" == "test" ]
then
  # For integration tests only. Tests in dev environment don't need server
  bundle exec rails s -b 0.0.0.0 -p $SERVER_PORT -P /app/tmp/pids/server-$RAILS_ENV.pid
else
  puma="/app/tmp/puma-$RAILS_ENV.rb"
  cp config/puma.rb $puma
  echo "pidfile '/app/tmp/pids/server-$RAILS_ENV.pid'" >> $puma
  echo "port $SERVER_PORT" >> $puma
  bundle exec puma -C $puma
fi
