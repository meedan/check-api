#!/bin/bash

cd test && rm -rf $EXCLUDE_DIRECTORIES && echo 'Running tests:' && ls && cd - && RUBYOPT='-W0' bundle exec rake parallel:test[6]
