#!/bin/bash


# generate configs with group and world read permissions.
umask 022

echo "Starting application configuration. Processing ENV settings."

# Move default configs into place.
# For most environments, these settings are overridden in ENV set from SSM.
(
  cd config
  if [ ! -f clean_db.yml ]; then
    cp clean_db.yml.example clean_db.yml
  fi
  if [ ! -f config.yml ]; then
    cp config.yml.example config.yml
  fi
  if [ ! -f credentials.json ]; then
    cp credentials.json.example credentials.json
  fi
  if [ ! -f database.yml ]; then
    cp database.yml.example database.yml
  fi
  if [ ! -f sidekiq.yml ]; then
    cp sidekiq.yml.example sidekiq.yml
  fi

  # If we are missing required configuration settings for QA and Live
  # environments, emit an error message explaining the omissions.
  #
  missing_configs=""

  # For production environments we use a secret token initializer from SSM:
  WORKTMP=$(mktemp)
  if [[ -z ${initializers_secret_token+x} ]]; then
    missing_configs="$missing_configs initializers_secret_token,"
    echo "Error: missing initializers_secret_token ENV setting. Using defaults."
  else
    echo ${initializers_secret_token} | base64 -d > $WORKTMP
    if (( $? != 0 )); then
      missing_configs="$missing_configs initializers_secret_token,"
      echo "Error: could not decode ENV var: ${initializers_secret_token} . Using defaults."
      rm $WORKTMP
    else
      echo "Using decoded secret_token initializer from ENV var: ${initializers_secret_token} ."
      mv $WORKTMP initializers/secret_token.rb
      sha1sum initializers/secret_token.rb
    fi
  fi

  # For sidekiq use config from SSM:
  WORKTMP=$(mktemp)
  if [[ -z ${sidekiq_config+x} ]]; then
    missing_configs="$missing_configs sidekiq_config,"
    echo "Error: missing sidekiq_config ENV setting. Using defaults."
  else
    echo ${sidekiq_config} | base64 -d > $WORKTMP
    if (( $? != 0 )); then
      missing_configs="$missing_configs sidekiq_config,"
      echo "Error: could not decode ENV var: ${sidekiq_config} . Using defaults."
      rm $WORKTMP
    else
      echo "Using decoded sidekiq config from ENV var: ${sidekiq_config} ."
      mv $WORKTMP sidekiq.yml
      sha1sum sidekiq.yml
    fi
  fi

  # For database configuration use SSM:
  WORKTMP=$(mktemp)
  if [[ -z ${database_config+x} ]]; then
    missing_configs="$missing_configs database_config,"
    echo "Error: missing database_config ENV setting. Using defaults."
  else
    echo ${database_config} | base64 -d > $WORKTMP
    if (( $? != 0 )); then
      missing_configs="$missing_configs database_config,"
      echo "Error: could not decode ENV var: ${database_config} . Using defaults."
      rm $WORKTMP
    else
      echo "Using decoded database config from ENV var: ${database_config} ."
      mv $WORKTMP database.yml
      sha1sum database.yml
    fi
  fi

  # Populate production environment config from SSM:
  WORKTMP=$(mktemp)
  if [[ -z ${environments_production+x} ]]; then
    missing_configs="$missing_configs environments_production,"
    echo "Error: missing environments_production ENV setting. Using defaults."
  else
    echo ${environments_production} | base64 -d > $WORKTMP
    if (( $? != 0 )); then
      missing_configs="$missing_configs environments_production,"
      echo "Error: could not decode ENV var: ${environments_production} . Using defaults."
      rm $WORKTMP
    else
      echo "Using decoded database config from ENV var: ${environments_production} ."
      mv $WORKTMP environments/production.rb
      sha1sum environments/production.rb
    fi
  fi

  # Populate credentials from SSM:
  WORKTMP=$(mktemp)
  if [[ -z ${credentials_config+x} ]]; then
    missing_configs="$missing_configs credentials_config,"
    echo "Error: missing credentials_config ENV setting. Using defaults."
  else
    echo ${credentials_config} | base64 -d > $WORKTMP
    if (( $? != 0 )); then
      missing_configs="$missing_configs credentials_config,"
      echo "Error: could not decode ENV var: ${credentials_config} . Using defaults."
      rm $WORKTMP
    else
      echo "Using decoded credentials config from ENV var: ${credentials_config} ."
      mv $WORKTMP credentials.json
      sha1sum credentials.json
    fi
  fi

  # If we are missing required configs in QA or Live environemnts emit an error
  # detailing the omitted configurations and exit.  This will promptly fail an
  # attempted deployment, rather than deferring to application failures.
  #
  if [[ "$DEPLOY_ENV" == "qa" || "$DEPLOY_ENV" == "live" ]]; then
    if [[ "$missing_configs" != "" ]]; then
      echo "Error: missing required configurations: $missing_configs exiting."
      kill 0
    fi
  fi
)

echo "Configuration complete."
exit 0
