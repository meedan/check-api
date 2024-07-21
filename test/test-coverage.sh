# #!/bin/bash

# apt-get install -y golang-go golang-glide
# printf '#!/bin/bash\ngo run /tmp/go/src/github.com/codeclimate/test-reporter/main.go $@\n' > test/cc-test-reporter && chmod +x test/cc-test-reporter
# export GOPATH=/tmp/go
# git config --global --add safe.directory /app
# mkdir -p /tmp/go/src/github.com/codeclimate
# git clone -b 0.10.3 https://github.com/codeclimate/test-reporter /tmp/go/src/github.com/codeclimate/test-reporter
# cd /tmp/go/src/github.com/codeclimate/test-reporter
# go mod init github.com/codeclimate/test-reporter
# go mod tidy
# apt-get install -y awscli
# cd -
# ./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$GITHUB_JOB_NAME.json ../coverage/.resultset.json
# aws s3 cp ../coverage/codeclimate.$GITHUB_JOB_NAME.json s3://check-api-travis/codeclimate/$GITHUB_REPO_SLUG/$GITHUB_BUILD_NUMBER/codeclimate.$GITHUB_JOB_NAME.json
# echo 'Combining and uploading coverage...'


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
apt-get install -y awscli
cd -
./test/cc-test-reporter format-coverage -t simplecov --output ../coverage/codeclimate.$GITHUB_JOB_NAME.json ../coverage/.resultset.json
aws s3 cp ../coverage/codeclimate.$GITHUB_JOB_NAME.json s3://check-api-travis/codeclimate/$GITHUB_REPO_SLUG/$GITHUB_BUILD_NUMBER/codeclimate.$GITHUB_JOB_NAME.json
echo 'Combining and uploading coverage...' && cd test && 
rm -rf ../coverage/*
aws s3 cp --recursive s3://check-api-travis/codeclimate/$GITHUB_REPO_SLUG/$GITHUB_BUILD_NUMBER/ ../coverage
if [[ $(ls ../coverage/codeclimate.* | wc -l) -eq 3 ]]
then
# Make sure we are not dealing with a file that is still being uploaded
previous_size=0
size=$(du -s ../coverage/ | cut -f1)
while [ $size -gt $previous_size ]
do
    previous_size=$size
    sleep 5
    size=$(du -s ../coverage/ | cut -f1)
done
./cc-test-reporter sum-coverage --output - --parts 3 ../coverage/codeclimate.* | sed 's/\/home\/runner\/work\/check-api\///g' > ../coverage/codeclimate.json
cat ../coverage/codeclimate.json | ./cc-test-reporter upload-coverage --input -
./cc-test-reporter show-coverage ../coverage/codeclimate.json
fi
&& cd -
echo 'Parallel tests runtime log' && cat tmp/parallel_runtime_test.log