# SleepGuardShared

Code shared by the SleepGuard apps (the SwiftUI app `SleepGuard` and the UIKit-shell app `SleepGuardUIKitWay`). One package, one version: a change here reaches every app the same way.

## Products

| Product | Imports | What it holds |
|---|---|---|
| `SleepCore` | Foundation | Sleep score formula and config, the detection state machine and its actor, and the plain value types they use (`SnoreIntensity`, `SoundCategory`, `SleepStage`, `SleepStageSegment`, `StageStats`, `RecordingGap`, `SnoreBurst`). No SwiftData, no UI, no clock. |
| `SleepStrings` | Foundation | `Localizable.xcstrings` and the generated `Strings` accessor. |

What does not belong here: persistence models, services, navigation, anything that differs between the apps.

## Using it from an app

- **While developing:** keep this repo checked out next to the app (`../SleepGuardShared`). The apps depend on it by path, so an edit here shows up on the app's next build.
- **Stored types:** `RecordingGap`, `SleepStageSegment`, `SnoreBurst` and the enums are persisted inside SleepGuard's SwiftData models. Changing their stored properties or raw values is a schema change for that app.

## Strings

1. Add entries to `Sources/SleepStrings/Resources/Strings.txt` (`key`, `key = value` or `"key" = "value"`), or edit `Localizable.xcstrings` directly with `"extractionState": "manual"`.
2. Run `python3 scripts/generate-xcstrings.py` (merges `Strings.txt`, then regenerates `Strings.swift`) or `python3 scripts/generate-strings.py` (regenerates only).
3. Never edit `Sources/SleepStrings/Strings.swift` by hand.

## Detection goldens

`Tests/SleepCoreTests/Fixtures/Replay` holds excerpts of a real recording and the decisions the state machine makes for them. A change that is meant to alter detection must re-record them on purpose with `sh scripts/record-replay-goldens.sh` and explain the diff.

## Tests

`sh scripts/run-tests.sh` runs `SleepCore` tests on macOS (`swift test`) and `SleepStrings` tests on the iOS Simulator (string catalogs need Xcode's build system).
