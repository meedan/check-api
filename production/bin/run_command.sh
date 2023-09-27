#!/bin/bash

# run the command using the $DEPLOYUSER

set -e

if [[ -z ${DEPLOY_ENV+x} ]]; then
	echo "DEPLOY_ENV must be in the environment. Exiting."
	exit 1
fi

# Create configuration files based on SSM and ENV settings.
bash /opt/bin/create_configs.sh

$@
