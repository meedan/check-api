#!/bin/bash

dir=$(pwd)
cd $(dirname "${BASH_SOURCE[0]}")
cp Dockerfile ..
cd ..

# Build
docker build -t lapis/checkdesk .

# Run
secret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
docker run -d -p 3000:80 --name checkdesk -e SECRET_KEY_BASE=$secret lapis/checkdesk

echo
docker ps | grep 'checkdesk'
echo

echo '-----------------------------------------------------------'
echo 'Now go to your browser and access http://localhost:3000/api'
echo '-----------------------------------------------------------'

rm Dockerfile
cd $dir
