#!/bin/bash

echo 'Setting up parallel test environment...'

echo 'Setting up parallel ElasticSearch indexes...'

bundle exec rails runner 'index = CheckConfig.get("elasticsearch_index") ; MediaSearch.create!(index, true) ; puts "Created ElasticSearch index named #{index}"'
TEST_ENV_NUMBER=1 bundle exec rails runner 'index = CheckConfig.get("elasticsearch_index") ; MediaSearch.create(index, true) ; puts "Created ElasticSearch index named #{index}"'
TEST_ENV_NUMBER=2 bundle exec rails runner 'index = CheckConfig.get("elasticsearch_index") ; MediaSearch.create(index, true) ; puts "Created ElasticSearch index named #{index}"'
TEST_ENV_NUMBER=3 bundle exec rails runner 'index = CheckConfig.get("elasticsearch_index") ; MediaSearch.create(index, true) ; puts "Created ElasticSearch index named #{index}"'
TEST_ENV_NUMBER=4 bundle exec rails runner 'index = CheckConfig.get("elasticsearch_index") ; MediaSearch.create(index, true) ; puts "Created ElasticSearch index named #{index}"'
TEST_ENV_NUMBER=5 bundle exec rails runner 'index = CheckConfig.get("elasticsearch_index") ; MediaSearch.create(index, true) ; puts "Created ElasticSearch index named #{index}"'
sleep 10

echo 'Setting up parallel databases...'

FAIL=0

bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=1 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=2 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=3 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=4 bundle exec rake db:create db:migrate &
TEST_ENV_NUMBER=5 bundle exec rake db:create db:migrate &

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
