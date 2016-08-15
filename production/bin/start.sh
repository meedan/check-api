#!/bin/bash

# start.sh
# the Dockerfile CMD

bundle exec rake db:migrate

echo
echo "migration complete... starting nginx"
echo

nginx