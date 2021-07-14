#!/bin/bash

if [ "$GITHUB_JOB_NAME" == "unit-tests" ] ; then
  PATTERN='controllers';
elif [ "$GITHUB_JOB_NAME" == "functional-tests" ] ; then
  PATTERN='models mailers integration workers lib'
fi
cd test && rm -rf $PATTERN && echo 'Running tests:' && ls && cd - && bundle exec rake parallel:test[5]
