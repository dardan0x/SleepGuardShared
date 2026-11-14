#!/bin/sh
# Re-records the detection replay goldens. Run this ONLY when a change is meant
# to alter detection, then review the diff it prints and explain each changed
# line in the PR. A normal test run never writes goldens.
#
# Usage: sh scripts/record-replay-goldens.sh
set -eu
cd "$(dirname "$0")/.."

RECORD_REPLAY_GOLDENS=1 swift test --filter SleepCoreTests

GOLDENS=Tests/SleepCoreTests/Fixtures/Replay
echo
if git diff --quiet -- "$GOLDENS" && [ -z "$(git ls-files --others --exclude-standard -- "$GOLDENS")" ]; then
  echo "Goldens unchanged."
else
  echo "Goldens changed. Review before committing:"
  git status --short -- "$GOLDENS"
  git --no-pager diff --stat -- "$GOLDENS"
fi
