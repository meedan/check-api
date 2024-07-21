#!/bin/bash

apt-get install -y golang-go golang-glide
printf '#!/bin/bash\ngo run /tmp/go/src/github.com/codeclimate/test-reporter/main.go $@\n' > test/cc-test-reporter && chmod +x test/cc-test-reporter
export GOPATH=/tmp/go
git config --global --add safe.directory /app
mkdir -p /tmp/go/src/github.com/codeclimate
git clone -b 0.10.3 https://github.com/codeclimate/test-reporter /tmp/go/src/github.com/codeclimate/test-reporter
cd /tmp/go/src/github.com/codeclimate/test-reporter
go mod init github.com/codeclimate/test-reporter
go mod tidy
apt install -y awscli
cd -
./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$GITHUB_JOB_NAME.json ../coverage/.resultset.json
aws s3 sync cp ../coverage/codeclimate.$GITHUB_JOB_NAME.json s3://check-api-travis/codeclimate/$GITHUB_REPO_SLUG/$GITHUB_BUILD_NUMBER/codeclimate.$GITHUB_JOB_NAME.json
echo 'Parallel tests runtime log' && cat tmp/parallel_runtime_test.log