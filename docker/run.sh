#!/bin/bash

dir=$(pwd)
cd $(dirname "${BASH_SOURCE[0]}")
cd ..

# Build
docker build -t meedan/checkdesk-api .

# Run
secret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
docker run -d -p 3000:80 --name checkdesk-api -e SECRET_KEY_BASE=$secret meedan/checkdesk-api

echo
docker ps | grep 'checkdesk-api'
echo

echo '-----------------------------------------------------------'
echo 'Now go to your browser and access http://localhost:3000/api'
echo '-----------------------------------------------------------'

