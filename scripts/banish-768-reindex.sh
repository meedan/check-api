#!/bin/bash

# substitute in the secerets that should be inserted in into the env from SSM
bundle exec rake check:migrate:remove_vector_768_and_reindex[$elasticsearch_host':'$elasticsearch_port,$elasticsearch_user,$elasticsearch_password]