#!/bin/bash
bundle exec rake db:create
bundle exec rake db:migrate
export SECRET_KEY_BASE=$(bundle exec rake secret)
bundle exec rake lapis:api_keys:create_dev
if [ "$RAILS_ENV" == "test" ] ; then
  sleep infinity # just wait for external commands
else
  exec bundle exec rails s -b 0.0.0.0
fi
