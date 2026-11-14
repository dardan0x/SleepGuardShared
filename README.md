# SleepGuardShared

Code shared by the SleepGuard apps (the SwiftUI app `SleepGuard` and the UIKit-shell app `SleepGuardUIKitWay`). One package, one version: a change here reaches every app the same way.

## Products

| Product | Imports | What it holds |
|---|---|---|
| `SleepCore` | Foundation | Sleep score formula and config, the detection state machine and its actor, and the plain value types they use (`SnoreIntensity`, `SoundCategory`, `SleepStage`, `SleepStageSegment`, `StageStats`, `RecordingGap`, `SnoreBurst`). No SwiftData, no UI, no clock. |
| `SleepStrings` | Foundation | `Localizable.xcstrings` and the generated `Strings` accessor. |

What does not belong here: persistence models, services, navigation, anything that differs between the apps.

## How the apps use it

Apps depend on a **released version**:

```swift
.package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.1.0")
```

Keep this repo checked out next to the apps (`../SleepGuardShared`). Each app has a **dev workspace** that adds this folder as a local package, which overrides the release:

| Build | Uses |
|---|---|
| The app's dev workspace (e.g. `SleepGuard.xcworkspace`) in Xcode | Your local checkout: edits here show up on the next build |
| The app's project, its package test script, its CI | The pinned release |

## Releasing a change

1. Here: change, run `sh scripts/run-tests.sh`, commit, push. CI runs this package's tests and builds SleepGuard against the commit.
2. Tag a release: `git tag -a 0.2.0 -m "What changed" && git push origin 0.2.0`. Semantic versioning; while on 0.x, bump the minor for anything an app must adapt to.
3. In each app: `sh scripts/bump-shared.sh 0.2.0`, run its tests, commit.

**Stored types:** `RecordingGap`, `SleepStageSegment`, `SnoreBurst` and the enums are persisted inside SleepGuard's SwiftData models. Changing their stored properties or raw values is a schema change for that app.

## Strings

1. Add entries to `Sources/SleepStrings/Resources/Strings.txt` (`key`, `key = value` or `"key" = "value"`), or edit `Localizable.xcstrings` directly with `"extractionState": "manual"`.
2. Run `python3 scripts/generate-xcstrings.py` (merges `Strings.txt`, then regenerates `Strings.swift`) or `python3 scripts/generate-strings.py` (regenerates only).
3. Never edit `Sources/SleepStrings/Strings.swift` by hand. CI fails if it is out of sync with the catalog.

## Detection goldens

`Tests/SleepCoreTests/Fixtures/Replay` holds excerpts of a real recording and the decisions the state machine makes for them. A change that is meant to alter detection must re-record them on purpose with `sh scripts/record-replay-goldens.sh` and explain the diff.

## Tests

`sh scripts/run-tests.sh` runs `SleepCore` tests on macOS (`swift test`) and `SleepStrings` tests on the iOS Simulator (string catalogs need Xcode's build system).
