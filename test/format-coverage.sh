#!/bin/bash

apt-get install -y awscli

if [ "$GITHUB_PULL_REQUEST" == "pull_request" ]
then
./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$GITHUB_JOB_NAME.json ../coverage/.resultset.json
aws s3 cp ../coverage/codeclimate.$GITHUB_JOB_NAME.json s3://check-api-travis/codeclimate/$GITHUB_REPO_SLUG/$GITHUB_BUILD_NUMBER/codeclimate.$GITHUB_JOB_NAME.json
fi

# #!/bin/bash

# apt-get install -y awscli

# if [ "$TRAVIS_PULL_REQUEST" == "false" ]
# then
#   ./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$TRAVIS_JOB_NAME.json ../coverage/.resultset.json
#   aws s3 cp ../coverage/codeclimate.$TRAVIS_JOB_NAME.json s3://check-api-travis/codeclimate/$TRAVIS_REPO_SLUG/$TRAVIS_BUILD_NUMBER/codeclimate.$TRAVIS_JOB_NAME.json
# fi
