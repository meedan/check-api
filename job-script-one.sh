#!/bin/bash

export PATTERN='models mailers integration workers lib' && cd test && rm -rf $PATTERN && echo 'Running tests:' && ls && cd - && bundle exec rake parallel:test[5] && cd test && ./format-coverage.sh && cd -