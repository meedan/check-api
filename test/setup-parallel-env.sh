#!/bin/bash

echo 'Setting up parallel databases'

FAIL=0

bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=1 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=2 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=3 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=4 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=5 bundle exec rake db:create db:migrate &

touch tmp/parallel_runtime_test.log
chmod +w tmp/parallel_runtime_test.log

for job in `jobs -p`
do
  echo $job
  wait $job || let "FAIL+=1"
done

echo $FAIL

if [ "$FAIL" == "0" ];
then
  exit 0
else
  exit 1
fi
