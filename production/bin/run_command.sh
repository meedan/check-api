#!/bin/bash

# run the command using the $DEPLOYUSER

set -e

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV  must be in the environment. Exiting."
	exit 1
fi

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done

$@