#!/bin/bash

# Wait for API
until curl --silent -XGET --fail http://api:${SERVER_PORT}; do printf '.'; sleep 1; done

if [[ ${RAILS_ENV} == "development" ]]; then
  bin/sidekiq
else
  bundle exec sidekiq
fi
