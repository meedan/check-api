#!/bin/sh
bundle exec rake db:create
bundle exec rake db:migrate
export SECRET_KEY_BASE=$(bundle exec rake secret)
bundle exec rake lapis:api_keys:create_dev
exec bundle exec rails s -b 0.0.0.0
