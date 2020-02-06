#!/bin/bash

if [[ "$TRAVIS_PULL_REQUEST" == "false" ]] && [[ $TRAVIS_TEST_RESULT == 0 ]]
then
  aws s3 cp --recursive s3://check-api-travis/codeclimate/$TRAVIS_REPO_SLUG/$TRAVIS_BUILD_NUMBER/ ../coverage
  ./cc-test-reporter sum-coverage --output - --parts 2 ../coverage/codeclimate.* | sed 's/\/home\/travis\/build\/meedan\/check-api\///g' | ./cc-test-reporter upload-coverage --input -
fi
