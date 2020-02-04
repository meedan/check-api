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


# sed in environmental variables
for ENV in $( env | cut -d= -f1); do
    config_replace "$ENV" "${!ENV}" /etc/nginx/sites-available/${APP}
done

if [ "$RAILS_ENV" == "test" ]; then
    # comment out the include
    sed -i'.bak' -e 's|include /etc/nginx/sites-available/test_404.conf|# include /etc/nginx/sites-available/test_404.conf|g' /etc/nginx/sites-available/${APP}
fi

echo "setting permissions for ${LOGFILE}"
touch ${LOGFILE}
chown ${DEPLOYUSER}:www-data ${LOGFILE}
chmod 775 ${LOGFILE}

echo PERSIST_DIRS $PERSIST_DIRS
for d in ${PERSIST_DIRS}; do
    d=/app/shared/files/${d}
    if [ ! -e "${d}" ]; then
        echo "creating directory ${d}"
        mkdir -p ${d}
    fi

#    echo "setting permissions for ${d}"
#    chown -R ${DEPLOYUSER}:www-data ${d}
#    find ${d} -type d -exec chmod 2777 {} \; # set the sticky bit on directories to preserve permissions
#    find ${d} -type f -exec chmod 0664 {} \; # files are 664
done


echo "tailing ${LOGFILE}"
tail -f ${LOGFILE} &

echo "starting nginx"
echo "--STARTUP FINISHED--"
nginx
