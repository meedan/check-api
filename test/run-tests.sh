#!/bin/bash

echo 'Waiting for ElasticSearch cluster to be healthy...'
curl -XGET 'http://localhost:9200/_cluster/health?wait_for_status=yellow&timeout=120s'
cd test && rm -rf $PATTERN && echo 'Running tests:' && ls && cd - && bundle exec rake parallel:test[5]
