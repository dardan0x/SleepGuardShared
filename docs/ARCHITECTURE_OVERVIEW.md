# Architecture overview

The detailed reference for SleepGuardShared: every product, every area of `SleepCore`, how each app consumes it module by module, versioning, and tests. The [README](../README.md) has the big picture.

## Contents

1. [Products](#products)
2. [How the apps use it](#how-the-apps-use-it)
3. [Versioning and releases](#versioning-and-releases)
4. [Tests and CI](#tests-and-ci)
5. [Strings](#strings)

---

## Products

| Product | Size | Imports | Holds |
|---|---|---|---|
| `SleepCore` | 45 files · 3.2k lines | Foundation | The night as values and every rule over it. No SwiftData, no UI, no clock, no singletons |
| `SleepStrings` | catalog + generated accessor | Foundation | `Localizable.xcstrings` and the generated `Strings` enum |
| `SleepMelodies` | 1 file + sounds | Foundation, `SleepCore` | The Snore Interrupter's built-in sound files; `SleepMelodies.url(for:)` |
| `SleepGuardDesignKit` | 38 files · 3.0k lines | SwiftUI, `SleepCore`, `SleepStrings` (re-exported) | `Theme` tokens and components that take values |
| `SleepGuardContentKit` | 46 files · 5.1k lines | SwiftUI, `SleepCore`, `SleepGuardDesignKit` (re-exported) | Each screen's loaded layout, with values, closures and slots in |

### `SleepCore`: the rules

The domain, as `Sendable` value types and pure functions. Everything that decides a number the user sees lives here.

| Area | Types | What it decides |
|---|---|---|
| `Night/` | `Night`, `NightEvent`, `NightSummary`, `NightEpisode`, `SnoringEpisodes`, `SleepStageBreakdown` | A night's metrics: snoring duration (from bursts, not event spans), event counts, episodes (events merged across short pauses), stage stats against the score's targets |
| `Score/` | `SleepScore`, `SleepScoreConfig`, `SleepScoreCacheVersion` | The 0–100 score: capped penalties for snoring time, episodes per hour, intensity, sleep talking, duration and stages. A version stamp of the formula and config, so an app knows when a cached score is stale |
| `Detection/` | `DetectionStateMachine`, `DetectionEngine` (actor), `SnoreClassifier`, `DetectionState` | Per-sample classification (none · quiet · light · loud · epic) and the event rules: start after sustained activity, close after silence, bursts, melody gaps, false-positive filters |
| `Audio/` | `AudioLevels`, `SpectralFeatures`, `SoundClassLabels` | The detection inputs: RMS and peak dB, features from an FFT's magnitudes, which SoundAnalysis classes count as snoring or talking |
| `Statistics/` | `NightDashboard`, `ScoreTrend`, `NightPeriod`, `CalendarMonth`, `NightDay`, `NightMonth` | The dashboard, trends, calendar and Last 7 Nights, from `NightSummary` values |
| `Playback/` | `ClipPlaylist`, `PlaybackGain`, `WaveformAccumulator` | The current clip, the joined timeline, seeking, auto-advance, the enhanced-audio boost and filter frequencies |
| `Interrupter/` | `SnoreInterrupterMode`, `Melody`, `CustomMelodies` | How long a melody plays, the catalog, recorded melodies, and how the gap it leaves is counted |
| `Briefing/` | `BriefingEngine`, `Briefing`, `BriefingSchedule`, `ProfilePrompt`, `LifestyleLog` | The morning briefing as values (greeting, headline, stats, insight, survey), when it's due, when to ask for the profile |
| `Report/` | `NightReport` | A night's report: rating, stats, stages and paged event rows |
| `Onboarding/` | `OnboardingPages` | Which pages show (Health only where a brand has it) and how one moves between them |
| `Recording/`, `Storage/`, `Profile/` | `RecordingDelay`, `RawLog`, `StoragePlan`, `SleepProfile` | The start delay, the raw sample log format, which nights lose audio under storage limits, the sleep profile |
| `Values/` | `SnoreIntensity`, `SoundCategory`, `SleepStage`, `SnoreBurst`, `RecordingGap` | Plain values that the apps also store |

**Design properties:**
- **Values in, values out.** The briefing returns `BriefingHeadline.normal(duration:snoringMinutes:score:isLastNight:)`, not a sentence. The content kit turns it into text, so the rule is tested without strings and the text is tested without the rule.
- **No hidden inputs.** `now`, the `Calendar` and random rolls are parameters. The briefing's content mode is seeded by the night, so the same night always gives the same briefing and the tests can check exact output.
- **Live detection is one ordered stream into an actor.** A recording sends every sample, melody start and stop, settings change and session end into `DetectionEngine` as a timestamped message. The actor runs the pure state machine and returns outputs in order. The apps perform the side effects (clips, gaps, the melody), so neither app can change detection state from a side path.
- **Pinned by replay goldens.** `Tests/SleepCoreTests/Fixtures/Replay` holds excerpts of a real night's samples and the decisions the state machine makes for them. A change that alters detection fails these tests until it re-records them on purpose (`sh scripts/record-replay-goldens.sh`) and explains the diff.

### `SleepGuardDesignKit`: tokens and components

- **`Theme`** (palette, typography, radii) is read from `@Environment(\.theme)`. `Theme.sleepGuard` is the default; UIKitWay's brands each build their own (violet Nocturne, teal Lite, warm Dawn), and every component follows.
- **Components take values through `init`**: `SleepScoreGauge`, `StatCard`, `NightTimeline`, `EventRow`, `CalendarMonthGrid`, `SnoringBarChart`, the player and bedside-clock pieces, the Snore Interrupter rows. No `@Injected`, no singletons, no persistence types, no product decisions.
- Every colour, font and radius comes from `Theme`. A new token is a stored property, so it's a source-breaking change for every app that builds a theme: bump the minor version.

### `SleepGuardContentKit`: screen content

One screen's loaded layout, drawn from values, with actions as closures and app-specific pieces as `@ViewBuilder` slots: `StatisticsDashboardContent`, `TrendsContent`, `CalendarContent`, `NightsListContent`, `NightDetailContent`, `PlayerContent`, `PrestartContent`, `BedsideClockContent`, `SessionSummaryContent`, `SettingsContent`, `OnboardingContent`, `BriefingContent`, `LearnContent`, `NightReportPDF` and more.

It owns no state beyond what it draws (a selected filter, a drag offset), and it does no loading or navigation. Each app keeps the **screen**: loading and `ViewState`, data access, dependency injection, navigation, alerts. The same content is hosted by two very different screens:

```swift
// SleepGuard: a SwiftUI container. The model comes from SwiftData, sheets are local state.
NightDetailContent(
  night: night, summary: night.summary(using: appConfig.sleepScoreConfig),
  filters: model.filters, filter: $model.selectedFilter,
  onPlay: { row in activeSheet = .player(initialEvent: model.event(for: row)) },
  onShowAll: { _ in activeSheet = .events },
  stages: { SleepStagesSection(session: session, scoreConfig: appConfig.sleepScoreConfig) },
  footer: { ShortEventsButton(count: model.shortEvents.count) { activeSheet = .shortEventsPlayer } })

// SleepGuardUIKitWay: a screen that only reports intent. A coordinator decides what each route does.
NightDetailContent(
  night: night, summary: detail.summary, filters: EventFilter.options(for: night.events), filter: $filter,
  onPlay: { row in routes.playEvents(row.playback(in: night.events), row.id) },
  onShowAll: { rows in routes.showAllEvents(rows, night.events) },
  stages: { /* the shared SleepStagesCard, when the brand has Apple Health */ },
  footer: { EmptyView() })
```

`NightReportPDF` renders `NightReport` as a paged US Letter PDF with `ImageRenderer` into a `CGContext`, so both apps export the same localized report.

---

## How the apps use it

### SleepGuard (SwiftUI)

| SleepGuard package | Uses | How |
|---|---|---|
| `Models` | `SleepCore` | `SleepSession+Night.swift` maps the SwiftData models to `Night`. `sleepScore`, `snoringDuration` and the cached score fields call `SleepCore`. Its tests are the parity check that the mapping loses nothing |
| `AudioEngine` | `SleepCore` | The tap computes `AudioLevels` and `SpectralFeatures`; the classifiers and `DetectionEngine` come from `SleepCore` |
| `Env` | `SleepCore`, `SleepMelodies` | `RealtimeDetectionTracker` feeds the engine's stream and performs its outputs on the main actor; the interrupter plays `SleepMelodies` |
| `DesignSystem` | DesignKit, ContentKit, Strings | `AppTheme` starts from `Theme.sleepGuard`; `SleepGuardKitAdapters` builds kit components from models; it re-exports the kits and `Strings` to the feature packages |
| Feature packages | ContentKit (through `DesignSystem`), `SleepCore` | Containers load with `@Query` or a state owner, map to `NightSummary` / `Night`, and host the content |

Local work: open `SleepGuard.xcworkspace`, which adds `../SleepGuardShared` as a local package and overrides the release. `SleepGuard.xcodeproj`, `scripts/run-tests.sh` and CI use the pinned release.

### SleepGuardUIKitWay (UIKit shell)

| UIKitWay module | Uses | How |
|---|---|---|
| `SleepDomain` (core) | `SleepCore` | `Night`, `NightSummary` and the rules are the domain's entities. Ports and use cases are written in them; the recording actor feeds `DetectionEngine` |
| `SleepPersistence`, `SleepAudio`, `SleepHealth` (adapters) | `SleepCore`, `SleepMelodies` | Map SwiftData records, audio buffers and HealthKit samples to and from `SleepCore` values |
| `ScreenKit` | DesignKit | `HostingScreen` puts a SwiftUI screen in a `UIHostingController` with the brand's `Theme` in its environment |
| Features | ContentKit, `SleepCore` | Each screen loads through its `Dependencies` and hosts the content; actions go out through `Routes` |
| Apps (brands) | DesignKit | Each brand's `Brand.swift` builds a `Theme`. A brand without Apple Health gets no stages card and no Health onboarding page, decided by the shared content's optional values |

Local work: `tuist generate` builds against `../SleepGuardShared`. `TUIST_SHARED_RELEASE=1 tuist generate` builds the pinned release, as CI does.

### Mapping, not sharing, the storage

The apps don't share persistence. SleepGuard's `@Model` classes and UIKitWay's SwiftData records are different types with different migration histories. Each maps to `Night` at its edge. A shared model would have forced one app's storage and actor isolation on the other. The cost is one mapping per app, covered by parity tests.

---

## Versioning and releases

Apps depend on an **exact** released version:

```swift
.package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.27.0")
```

Exact pins make a shared change an explicit decision in each app: a release reaches an app only when that app bumps to it and its own tests pass. 27 releases so far (0.1.0 → 0.27.0), roughly one per migrated feature.

**Releasing a change:**
1. Here: change, run `sh scripts/run-tests.sh`, commit, push. CI runs this repo's tests and builds SleepGuard against the commit.
2. Tag: `git tag -a 0.28.0 -m "What changed" && git push origin 0.28.0`. Semantic versioning; while on 0.x, bump the minor for anything an app must adapt to.
3. In each app: `sh scripts/bump-shared.sh 0.28.0` (rewrites every manifest's pin and resolves), run all its tests, commit the manifests and `Package.resolved`.

**Day to day:** both apps can build against the local checkout instead (above), so a change here and its use in an app are developed together and released afterwards.

**Stored types:** `RecordingGap`, `SleepStageSegment`, `SnoreBurst` and the enums are stored inside SleepGuard's SwiftData models. Changing their stored properties or raw values is a schema change for that app, and is treated as one.

---

## Tests and CI

**251 Swift Testing tests.** `sh scripts/run-tests.sh` runs them all:

| Target | Tests | Runs on | Covers |
|---|---:|---|---|
| `SleepCoreTests` | 208 | macOS (`swift test`) | Every rule: score, night metrics, episodes, statistics, playback, interrupter, briefing, report, storage plan, and detection against replay goldens from a real night |
| `SleepGuardContentKitTests` | 27 | iOS Simulator | Every screen's content rendered in two themes; briefing text mapping; the PDF has one page per page of rows |
| `SleepGuardDesignKitTests` | 12 | iOS Simulator | Every component rendered in two themes; a theme change changes the output |
| `SleepStringsTests`, `SleepMelodiesTests` | 4 | iOS Simulator | The catalog loads; every built-in melody has its file |

Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR=/some/dir` to keep the rendered PNGs for review. `ImageRenderer` can't draw UIKit-backed views (`List`, `ScrollView` contents, `Toggle`, segmented and wheel `Picker`), so tests render the part inside them, and the apps' own tests check the rest.

**CI** (`.github/workflows/tests.yml`, every push to `main` and every PR):

| Job | Checks |
|---|---|
| `core` | `SleepCore` tests on macOS, including the replay goldens |
| `ui` | `Strings.swift` matches the catalog; string and design kit tests on the simulator |
| `sleepguard` | Checks out SleepGuard next to this commit and builds its dev workspace against it, so a breaking change fails here, before a release |

Not yet: CI doesn't also build SleepGuardUIKitWay against the candidate commit. That app catches a breaking change when it bumps, not before the tag.

---

## Strings

1. Add entries to `Sources/SleepStrings/Resources/Strings.txt` (`key`, `key = value` or `"key" = "value"`), or edit `Localizable.xcstrings` directly with `"extractionState": "manual"`.
2. Run `python3 scripts/generate-xcstrings.py` (merges `Strings.txt`, then regenerates `Strings.swift`) or `python3 scripts/generate-strings.py` (regenerates only).
3. Never edit `Sources/SleepStrings/Strings.swift` by hand. CI fails if it doesn't match the catalog.

Keys are dot-separated by context (`session.summary.title`). Both apps reach strings only through `Strings.`; each app's CI rejects user-facing literals.
