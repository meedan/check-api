#!/bin/bash

apt-get install -y golang-go golang-glide
printf '#!/bin/bash\ngo run /tmp/go/src/github.com/codeclimate/test-reporter/main.go $@\n' > test/cc-test-reporter && chmod +x test/cc-test-reporter
export GOPATH=/tmp/go
mkdir -p /tmp/go/src/github.com/codeclimate
git clone https://github.com/codeclimate/test-reporter /tmp/go/src/github.com/codeclimate/test-reporter

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# format coverage
# ./test/format-coverage.sh
if [ "$GITHUB_JOB_NAME" == "unit-tests" ] ; then
  PATTERN='controllers';
elif [ "$GITHUB_JOB_NAME" == "functional-tests" ] ; then
  PATTERN='models-mailers-integration-workers-lib'
fi

echo "Uploading coverage report to S3..."
./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$PATTERN.json ../coverage/.resultset.json
/usr/local/bin/aws s3 cp ../coverage/codeclimate.$PATTERN.json s3://check-api-travis/codeclimate/meedan/check-api/$GITHUB_JOB_NUMBER/codeclimate.$PATTERN.json
