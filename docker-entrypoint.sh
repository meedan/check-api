#!/bin/bash
bundle exec rake db:create
bundle exec rake db:migrate
export SECRET_KEY_BASE=$(bundle exec rake secret)
bundle exec rake lapis:api_keys:create_dev
bundle exec rails s -b 0.0.0.0 -p $SERVER_PORT -P /app/tmp/pids/server-$RAILS_ENV.pid
