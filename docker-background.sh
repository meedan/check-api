#!/bin/bash

# Wait for API
until curl --silent -XGET --fail http://api:${SERVER_PORT}; do printf '.'; sleep 1; done

bundle exec sidekiq
