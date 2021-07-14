#!/bin/bash

echo 'Waiting for ElasticSearch cluster to be healthy...'
until curl -I -f --silent  -XGET 'http://localhost:9200/_cluster/health?wait_for_status=yellow&timeout=120s'; do printf '.'; sleep 1; done

if [ "$GITHUB_JOB_NAME" == "unit-tests" ] ; then
  PATTERN='controllers';
elif [ "$GITHUB_JOB_NAME" == "functional-tests" ] ; then
  PATTERN='models mailers integration workers lib'
fi
cd test && rm -rf $PATTERN && echo 'Running tests:' && ls && cd - && bundle exec rake parallel:test[5]
