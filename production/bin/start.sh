#!/bin/bash

# start.sh
# the Dockerfile CMD

LOGFILE=${DEPLOYDIR}/log/${RAILS_ENV}.log

function config_replace() {
    # sed -i "s/ddRAILS_ENVdd/${RAILS_ENV}/g" /etc/nginx/sites-available/${APP}
    VAR=$1
    VAL=$2
    FILE=$3
    #    echo evaluating $VAR $VAL $FILE;
    if grep --quiet "dd${VAR}dd" $FILE; then
	echo "setting $VAR to $VAL in $FILE"
	CMD="s/dd${VAR}dd/${VAL}/g"
	sed -i'.bak' -e ${CMD} ${FILE}
    fi
}

#since GITHUB_TOKEN environment variable is a json object, we need parse the value
#This function is here due to a limitation by "secrets manager"
function getParsedGithubToken(){
    
  echo $GITHUB_TOKEN | jq -r .GITHUB_TOKEN

}

if [[ -z ${GITHUB_TOKEN+x} || -z ${DEPLOY_ENV+x} || -z ${APP+x} ]]; then
	echo "GITHUB_TOKEN, DEPLOY_ENV and APP must be in the environment.   Exiting."
	exit 1
fi

GITHUB_TOKEN_PARSED=$(getParsedGithubToken)

if [ ! -d "configurator" ]; then git clone https://${GITHUB_TOKEN_PARSED}:x-oauth-basic@github.com/meedan/configurator ./configurator; fi
d=configurator/check/${DEPLOY_ENV}/${APP}/; for f in $(find $d -type f); do cp "$f" "${f/$d/}"; done

mkdir -p /app/tmp/pids
puma="/app/tmp/puma-$RAILS_ENV.rb"
cp config/puma.rb $puma
echo "pidfile '/app/tmp/pids/server-$RAILS_ENV.pid'" >> $puma
echo "port $SERVER_PORT" >> $puma
bundle exec puma -C $puma