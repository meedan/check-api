#!/bin/bash

cd test && rm -rf $PATTERN && echo 'Running tests:' && ls && cd - && RUBYOPT='-W0' bundle exec rake parallel:test[6]
