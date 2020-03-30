#!/bin/bash

if [[ "$TRAVIS_PULL_REQUEST" == "false" ]] && [[ $TRAVIS_TEST_RESULT == 0 ]]
then
  aws s3 cp --recursive s3://check-api-travis/codeclimate/$TRAVIS_REPO_SLUG/$TRAVIS_BUILD_NUMBER/ ../coverage
  if [[ $(ls ../coverage/codeclimate.* | wc -l) -eq 2 ]]
  then
    ./cc-test-reporter sum-coverage --output - --parts 2 ../coverage/codeclimate.* | sed 's/\/home\/travis\/build\/meedan\/check-api\///g' > ../coverage/codeclimate.json
    cat ../coverage/codeclimate.json | ./cc-test-reporter upload-coverage --input -
    ./cc-test-reporter show-coverage ../coverage/codeclimate.json
  fi
fi
