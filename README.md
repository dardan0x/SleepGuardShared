# SleepGuardShared

Code shared by the SleepGuard apps (the SwiftUI app `SleepGuard` and the UIKit-shell app `SleepGuardUIKitWay`). One package, one version: a change here reaches every app the same way.

## Products

| Product | Imports | What it holds |
|---|---|---|
| `SleepCore` | Foundation | **The night:** `Night`, `NightEvent`, `NightEpisode`, `NightSummary` and the rules over them (`SnoringEpisodes`; `Night` metrics: snoring duration, event count, stage stats, score inputs, score, summary; `SleepStageBreakdown`: time, share and status per stage against the score's targets, and the stage penalty). **The formula and detection:** sleep score and config, the detection state machine and its actor. **Value types:** `SnoreIntensity`, `SoundCategory`, `SleepStage`, `SleepStageSegment`, `StageStats`, `RecordingGap`, `SnoreBurst`. **Settings rules:** `StoragePlan` (which nights lose their audio under the storage limits) and `StorageLimits`, `RecordingDelay` (start delay options, countdown), the raw log format (`RawLog`, `SnoreSample`, `RawLogMetadata`), the profile (`SleepProfile`). No SwiftData, no UI, no clock. Apps map their own storage to `Night` and call these rules, so they compute the same numbers. |
| `SleepStrings` | Foundation | `Localizable.xcstrings` and the generated `Strings` accessor. |
| `SleepGuardDesignKit` | SwiftUI, `SleepCore`, `SleepStrings` (re-exported) | **Tokens:** `Theme` (palette, typography, radii) passed through `@Environment(\.theme)`; `Theme.sleepGuard` is the default. **Components** that only take values: cards and gauges (`StatCard`, `SleepScoreGauge`, `SessionStatsGrid`, `StatTile`), charts (`MiniBarChart`, `SnoringBarChart`, `WeekStrip`, `CalendarMonthGrid`), layout (`FlowLayout`), sleep stages (`SleepStageHypnogram`, `SleepStageLegend`), night pieces (`NightTimeline`, `EventRow`, `EventCard`, `NightRow`, `NightCard`, `DayRow`, banners), player pieces (`PlayerHeader`, `ClipWaveform`, `PlayerControls`, `PlayerEventRow`, `EnhancedAudioToggle`), recording pieces (`PrestartHeader`, `BedsideClockFace`, `SessionSummaryHeader`, …), buttons. No product decisions. |
| `SleepGuardContentKit` | SwiftUI, `SleepCore`, `SleepGuardDesignKit` (re-exported) | **Screen content:** one screen's loaded layout, values and actions in: `StatisticsDashboardContent`, `TrendsContent`, `CalendarContent`, `LastSevenNightsContent`, `NightsListContent`, `NightDetailContent`, `EventsGridContent`, `PlayerContent` / `PlayerCard`, `PrestartContent` (with `PrestartDelayOptions` for its slot), `RecordingCountdownContent`, `BedsideClockContent`, `SessionSummaryContent`, `SettingsContent` (optional sections and rows: `nil` hides one), `ProfileEditorContent`, `SleepStagesCard` and `SleepStagesInfoContent` (the stages sheet), and empty / loading content. App-only extras go in `@ViewBuilder` slots. Each app hosts it in its own screen (loading, navigation, DI); see the apps' ADRs on shared screen content. |

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

`sh scripts/run-tests.sh` runs `SleepCore` tests on macOS (`swift test`) and the `SleepStrings`, `SleepGuardDesignKit` and `SleepGuardContentKit` tests on the iOS Simulator. The kit tests render every component and every screen's content in two themes; set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR=/some/dir` to keep the images. `ImageRenderer` can't draw UIKit-backed views (`List`, `ScrollView` contents, `Toggle`, segmented `Picker`): render the part inside them, and check the rest in the apps.

## Design kit rules

- Components take data through `init` and read the theme from the environment. No `@Injected`, no singletons, no domain or persistence types: an app maps its own models to the plain values a component takes.
- Every colour, text font and radius comes from `Theme`. Large numbers keep `.rounded`.
- A new token goes into `Palette`/`Typography`/`Radii` and into `Theme.sleepGuard`; every app that builds its own theme must then set it (adding a stored property is a source-breaking change: bump the minor version).
