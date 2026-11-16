#!/bin/sh
# Runs the package's tests.
#
#   SleepCore is Foundation-only, so its tests run on macOS with `swift test`.
#   SleepStrings needs Xcode's build system (command-line SwiftPM doesn't
#   compile string catalogs), and SleepGuardDesignKit and SleepGuardContentKit
#   render with UIKit, so they run on the iOS Simulator.
#
# Usage: sh scripts/run-tests.sh
# Env:   DESTINATION (default: the pinned iPhone 16e, iOS 26.2 simulator)
set -eu
cd "$(dirname "$0")/.."

DESTINATION=${DESTINATION:-"platform=iOS Simulator,id=BD630AD5-5A05-4663-8F1B-A17283EBCBF5"}

swift test --filter SleepCoreTests
xcodebuild test -scheme SleepGuardShared-Package -destination "$DESTINATION" \
  -derivedDataPath .build/xcode-derived-data -only-testing:SleepStringsTests -only-testing:SleepGuardDesignKitTests -only-testing:SleepGuardContentKitTests | grep -E "error:|✘|Test run with"
