#!/bin/bash

pip install --user awscli

echo "$TRAVIS_JOB_NAME"

if [ "$TRAVIS_JOB_NAME" == "unit-tests" ] ; then
  PATTERN='controllers';
else
  PATTERN='models mailers integration workers lib'
fi

if [ "$TRAVIS_PULL_REQUEST" == "false" ]
then
  name=$(echo $PATTERN | sed 's/ /-/g')
  ./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$name.json ../coverage/.resultset.json
  aws s3 cp ../coverage/codeclimate.$name.json s3://check-api-travis/codeclimate/$TRAVIS_REPO_SLUG/$TRAVIS_BUILD_NUMBER/codeclimate.$name.json
fi
