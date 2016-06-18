#!/bin/bash

dir=$(pwd)
cd $(dirname "${BASH_SOURCE[0]}")
cd ..

# Remove existing
docker rm -f checkdesk-api

# Build
docker build -t meedan/checkdesk-api .

# Run
secret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
docker run -p 3000:3000 --name checkdesk-api -e SECRET_KEY_BASE=$secret meedan/checkdesk-api
