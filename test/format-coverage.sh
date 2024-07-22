#!/bin/bash

apt-get install -y awscli

if [ "$GITHUB_EVENT" == "pull_request" || "$GITHUB_EVENT" == "push"]
then
./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$GITHUB_JOB_NAME.json ../coverage/.resultset.json
aws s3 cp ../coverage/codeclimate.$GITHUB_JOB_NAME.json s3://check-api-github/codeclimate/$GITHUB_REPO/$GITHUB_BUILD_NUMBER/codeclimate.$GITHUB_JOB_NAME.json
fi

