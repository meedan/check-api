#!/bin/bash

if [[ "$GITHUB_EVENT" == "pull_request" || "$GITHUB_EVENT" == "push"]] && [[ "$GITHUB_TEST_RESULT" == 'success' ]]
then
  rm -rf ../coverage/*
  aws s3 cp --recursive s3://check-api-github/codeclimate/$GITHUB_REPO/$GITHUB_BUILD_NUMBER/ ../coverage
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
fi
