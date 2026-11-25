#!/bin/sh
# Warns when an app pins this package more than MAX_MINORS minor releases
# behind the newest tag. Skew is allowed (each app adopts a release on purpose),
# but it should be visible and short-lived.
#
# Usage: sh scripts/check-consumer-skew.sh <app checkout> [MAX_MINORS]
# Needs the tags: check out with fetch-depth 0.
set -eu
APP=$1
MAX_MINORS=${2:-2}
cd "$(dirname "$0")/.."

LATEST=$(git tag --list '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1)
PINNED=$(grep -rhoE 'SleepGuardShared\.git", exact: "[0-9]+\.[0-9]+\.[0-9]+"' "$APP" --include=Package.swift \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | head -1)
[ -n "$LATEST" ] && [ -n "$PINNED" ] || { echo "No tag or no pin found; skipping."; exit 0; }

minor() { echo "$1" | awk -F. '{ print $1 * 1000 + $2 }'; }
BEHIND=$(( $(minor "$LATEST") - $(minor "$PINNED") ))
echo "$(basename "$APP") pins $PINNED; newest tag is $LATEST ($BEHIND minor(s) behind)."
if [ "$BEHIND" -gt "$MAX_MINORS" ]; then
  echo "::warning::$(basename "$APP") is $BEHIND minor releases behind SleepGuardShared $LATEST (pins $PINNED). Bump it with its bump-shared.sh."
fi
