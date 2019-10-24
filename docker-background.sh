#!/bin/bash

# Wait for API
until curl --silent -XGET --fail http://api:${SERVER_PORT}; do printf '.'; sleep 1; done

# Static Files Server
bundle exec ruby bin/static-files-server &

# Sidekiq
bin/sidekiq
