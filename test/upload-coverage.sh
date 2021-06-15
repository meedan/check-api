#!/bin/bash

# upload coverage
echo 'Combining and uploading coverage report to codeclimate...'
aws s3 cp --recursive s3://check-api-travis/codeclimate/meedan/check-api/$GITHUB_JOB_ID/ ../coverage_reports/
if [[ $(ls ../coverage_reports/codeclimate.* | wc -l) -eq 2 ]]; then
    ./test/cc-test-reporter sum-coverage --output - --parts 2 ../coverage_reports/codeclimate.* | sed 's/\/home\/travis\/build\/meedan\/check-api\///g' > ../coverage_reports/codeclimate.json
    cat ../coverage_reports/codeclimate.json | ./test/cc-test-reporter upload-coverage --input -
    ./test/cc-test-reporter show-coverage ../coverage_reports/codeclimate.json
fi
echo 'Parallel tests runtime log' && cat tmp/parallel_runtime_test.log
