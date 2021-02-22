#!/bin/bash

export PATTERN='controllers' && cd test && rm -rf $PATTERN && echo 'Running tests:' && ls && cd - && bundle exec rake parallel:test[5]