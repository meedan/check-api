#!/bin/bash

# For batch jobs, we may have multiple steps to perform.
# This is distinct from the usual runtime invocation where one command
# is invoked and runs forever.
#
# To facilitate arbitrary batch scripts, we pass them in the task ENV as
# variable `batch_entrypoint`. This setting is then decoded and invoked
# inside the batch task for desired processing.
#
if [[ -z ${batch_entrypoint+x} ]]; then
  echo "Error: missing batch_entrypoint ENV variable setting."
  echo "Please encode the batch entrypoint script into ENV."  
  exit 1
fi

WORKTMP=$(mktemp)
echo ${batch_entrypoint} | base64 -d > $WORKTMP
if (( $? != 0 )); then
  echo "Error: could not decode batch_entrypoint ENV var: ${batch_entrypoint} ."
  exit 2
fi

echo -n "Decoded batch entrypoint. Checksum: "
sha1sum $WORKTMP

START=$(date --utc)
echo "Invoking batch entrypoint."
bash $WORKTMP
END=$(date --utc)

echo "Batch job complete. Started $START , finished $END ."
