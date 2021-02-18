#!/bin/bash

apt-get install -y golang-go golang-glide
printf '#!/bin/bash\ngo run /tmp/go/src/github.com/codeclimate/test-reporter/main.go $@\n' > test/cc-test-reporter && chmod +x test/cc-test-reporter
export GOPATH=/tmp/go
mkdir -p /tmp/go/src/github.com/codeclimate
git clone https://github.com/codeclimate/test-reporter /tmp/go/src/github.com/codeclimate/test-reporter
echo 'Combining and uploading coverage...' && cd test && ./sum-upload-coverage.sh && cd -
echo 'Parallel tests runtime log' && cat tmp/parallel_runtime_test.log