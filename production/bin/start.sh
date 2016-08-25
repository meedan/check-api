#!/bin/bash

# start.sh
# the Dockerfile CMD

UPLOADS=${DEPLOYDIR}/shared/files/uploads

# TODO only run this on ${PRIMARY} nodes, perhaps in an out-of-band process during major multi-node deployments
echo "running migrations"
bundle exec rake db:migrate

echo "setting permissions for uploads"
chown -R ${DEPLOYUSER}:www-data ${UPLOADS}
find ${UPLOADS} -type d -exec chmod 2777 {} \; # set the sticky bit on directories to preserve permissions
find ${UPLOADS} -type f -exec chmod 0664 {} \; # files are 664

echo "starting nginx"

nginx