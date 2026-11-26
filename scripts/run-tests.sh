#!/bin/sh
# Runs the package's tests.
#
#   SleepCore is Foundation-only, so its tests run on macOS with `swift test`.
#   SleepStrings needs Xcode's build system (command-line SwiftPM doesn't
#   compile string catalogs), and SleepGuardDesignKit and SleepGuardContentKit
#   render with UIKit, and SleepAudioKit needs AVAudioSession, so they run on
#   the iOS Simulator.
#
# Usage: sh scripts/run-tests.sh
# Env:   DESTINATION (default: the pinned iPhone 16e, iOS 26.2 simulator)
set -eu
cd "$(dirname "$0")/.."

# No re-exports: every product imports what it uses (consumers declare theirs).
if grep -rn '@_exported' Sources Tests; then
  echo "error: @_exported import found; import the module where it is used" >&2
  exit 1
fi

DESTINATION=${DESTINATION:-"platform=iOS Simulator,id=BD630AD5-5A05-4663-8F1B-A17283EBCBF5"}

swift test --filter "SleepCoreTests|SleepStoreTests|SleepFilesTests|SleepHealthKitTests|SleepSettingsTests|SleepNotificationsTests"
xcodebuild test -scheme SleepGuardShared-Package -destination "$DESTINATION" \
  -derivedDataPath .build/xcode-derived-data -only-testing:SleepStringsTests -only-testing:SleepGuardDesignKitTests -only-testing:SleepGuardContentKitTests -only-testing:SleepAudioKitTests | grep -E "error:|✘|Test run with"
