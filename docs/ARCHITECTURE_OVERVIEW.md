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
| `SleepCore` | 53 files · 3.8k lines | Foundation | The night as values and every rule over it. No SwiftData, no UI, no clock, no singletons |
| `SleepStore` | 4 · 311 | SwiftData, `SleepCore`, `SleepLogging` | The nights database both apps store: `NightRecord` / `NightEventRecord`, their mapping to `Night`, the stored summary, `SleepStoreSchema` (versioned, migration plan) and `SleepStore.open` |
| `SleepAudioKit` | 13 · 1.3k | AVFoundation, SoundAnalysis, Accelerate, `SleepCore`, `SleepLogging`, `SleepMelodies` | Capture (`CaptureEngine`), clip compression, playback (`ClipPlayerEngine`), waveforms, clip spectrum and extraction, melody playback, recording and files. iOS only |
| `SleepFiles` | 5 · 350 | Foundation, `SleepCore`, `SleepLogging` | The one file layout (`StorageLocation`), the clips folder, the raw log, the checkpoint, profile and survey files |
| `SleepSettings` | 1 · 199 | Foundation, `SleepCore` | `PreferencesDefaults`: the settings both apps have, in UserDefaults |
| `SleepHealthKit` | 1 · 94 | HealthKit, `SleepCore` | `HealthKitSleep`: a night in Apple Health and its stages read back |
| `SleepLogging` | 1 · 40 | os | `Log.<category>` and the signposter |
| `SleepNotifications` | 1 · 27 | UserNotifications, `SleepStrings` | `StartNotification`: the start-delay notification |
| `SleepStrings` | catalog + generated accessor | Foundation | `Localizable.xcstrings` and the generated `Strings` enum |
| `SleepMelodies` | 1 file + sounds | Foundation, `SleepCore` | The Snore Interrupter's built-in sound files; `SleepMelodies.url(for:)` |
| `SleepGuardDesignKit` | 37 · 3.1k | SwiftUI, `SleepCore`, `SleepStrings` | `Theme` tokens and components that take values |
| `SleepGuardContentKit` | 49 · 5.4k | SwiftUI, `SleepCore`, `SleepGuardDesignKit`, `SleepStrings` | Each screen's loaded layout, with values, closures and slots in |

No product re-exports another: each imports, and declares, what it uses (since 0.37.0).

### `SleepCore`: the rules

The domain, as `Sendable` value types and pure functions. Everything that decides a number the user sees lives here.

| Area | Types | What it decides |
|---|---|---|
| `Night/` | `Night`, `NightEvent`, `NightSummary`, `NightEpisode`, `SnoringEpisodes`, `SleepStageBreakdown` | A night's metrics: snoring duration (from bursts, not event spans), event counts, episodes (events merged across short pauses), stage stats against the score's targets |
| `Score/` | `SleepScore`, `SleepScoreConfig`, `SleepScoreCacheVersion` | The 0–100 score: capped penalties for snoring time, episodes per hour, intensity, sleep talking, duration and stages. A version stamp of the formula and config, so an app knows when a cached score is stale |
| `Detection/` | `DetectionStateMachine`, `DetectionEngine` (actor), `SnoreClassifier`, `SpeechClassifier`, `LiveSampleClassifier`, `SampleDecimator`, `DetectionState` | Exactly 20 Hz samples from the capture, per-sample classification (none · quiet · light · loud · epic), and the event rules: start after sustained activity, close after silence, bursts, melody and interruption gaps, false-positive filters |
| `Audio/` | `AudioLevels`, `SpectralFeatures`, `SoundClassLabels` | The detection inputs: RMS and peak dB, features from an FFT's magnitudes, which SoundAnalysis classes count as snoring or talking |
| `Statistics/` | `NightDashboard`, `ScoreTrend`, `NightPeriod`, `CalendarMonth`, `NightDay`, `NightMonth` | The dashboard, trends, calendar and Last 7 Nights, from `NightSummary` values |
| `Playback/` | `ClipPlaylist`, `PlaybackGain`, `WaveformAccumulator` | The current clip, the joined timeline, seeking, auto-advance, the enhanced-audio boost and filter frequencies |
| `Interrupter/` | `SnoreInterrupterMode`, `Melody`, `CustomMelodies` | How long a melody plays, the catalog, recorded melodies, and how the gap it leaves is counted |
| `Briefing/` | `BriefingEngine`, `Briefing`, `BriefingSchedule`, `ProfilePrompt`, `LifestyleLog` | The morning briefing as values (greeting, headline, stats, insight, survey), when it's due, when to ask for the profile |
| `Report/` | `NightReport` | A night's report: rating, stats, stages and paged event rows |
| `Onboarding/` | `OnboardingPages` | Which pages show (Health only where a brand has it) and how one moves between them |
| `Recording/`, `Storage/`, `Profile/`, `Settings/` | `RecordingDelay`, `RawLog`, `CaptureSample` / `CaptureEvent`, `StoragePlan`, `StorageSweep`, `NightFiles`, `RawRecording`, `SleepProfile`, `SleepPreferences` | The start delay, the raw sample log format, what the capture yields, which nights lose audio under storage limits and which files nothing names, the sleep profile, the settings both apps have |
| `Samples/` | `SampleNights` | Deterministic Debug nights (with clips and survey answers) both apps seed |
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

Behaviour is shared, protocols are not: each app reaches the shared code through its own protocols or ports, with its own dependency injection, state and isolation.

### SleepGuard (SwiftUI)

| SleepGuard package | Uses | How |
|---|---|---|
| `Models` | `SleepCore`, `SleepStore`, `SleepFiles`, `SleepLogging` | SleepGuard's reads on the shared records (`NightRecord+SleepGuard`), the launch pass that refreshes stale summaries, the file layout (`SleepGuardStorage`). Its tests are the parity check against the shared rules |
| `AudioEngine` | `SleepAudioKit`, `SleepCore`, `SleepLogging` | `AudioRecorder` wraps `CaptureEngine` behind `AudioRecording`, publishing levels and confidences for the screens |
| `Services` | `SleepCore`, `SleepStore`, `SleepAudioKit`, `SleepFiles`, `SleepNotifications`, `SleepMelodies`, `SleepLogging` | `RealtimeDetectionTracker` holds `LiveSampleClassifier` and feeds the engine; `SessionCommitter` writes records; the interrupter, melody store, checkpoint, profile and survey stores wrap the shared code behind protocols |
| `Config`, `Health` | `SleepSettings`; `SleepHealthKit` | `UserPreferences` over `PreferencesDefaults`; `HealthKitSync` over `HealthKitSleep` |
| `DesignSystem` | DesignKit, ContentKit, Strings, `SleepStore` | `Theme` extensions and `SleepGuardKitAdapters` (kit components from records). No re-exports |
| Feature packages | ContentKit, DesignKit, Strings, `SleepStore`, `SleepCore` (each only what it uses) | Containers load with `@Query` or a state owner, build `Night` / `NightSummary` and host the content |
| App target | `SleepCore`, `SleepStore`, `SleepFiles`, `SleepLogging`, DesignKit, Strings | Declared in the Xcode project (exact pin, under Package Dependencies); opens the store with `SleepStore.open` |

To try unreleased code: add `../SleepGuardShared` to `SleepGuard.xcworkspace` in Xcode for the time being, or build a throwaway workspace that lists both (as this repo's CI does). Everything else uses the pinned release.

### SleepGuardUIKitWay (UIKit shell)

| UIKitWay module | Uses | How |
|---|---|---|
| `SleepDomain` (core) | `SleepCore` | `Night`, `NightSummary` and the rules are the domain's entities. Ports and use cases are written in them; the recording actor decimates, classifies with `LiveSampleClassifier` and feeds `DetectionEngine` |
| `SleepPersistence` (adapter) | `SleepStore`, `SleepFiles`, `SleepSettings`, `SleepLogging`, `SleepCore` | A `@ModelActor` repository over the shared records behind `SessionRepository`; file stores over the shared files; preferences over `PreferencesDefaults` |
| `SleepAudio` (adapter) | `SleepAudioKit`, `SleepCore` | Factories, and conformances of the kit's types to `AudioCapture`, `ClipPlayer`, `ClipWaveformSource` and the melody ports |
| `SleepHealth` (adapter) | `SleepHealthKit`, `SleepCore`, `SleepLogging` | Behind `SleepStageSource` / `HealthAccess` |
| `ScreenKit` | DesignKit | Its hosting helpers put the brand's `Theme` in the environment of everything a screen hosts |
| Features | ContentKit, DesignKit, Strings, `SleepCore` | Each screen loads through its `Dependencies` and hosts the content; actions go out through `Routes` |
| `AppShell`, brands | DesignKit, Strings, `SleepCore`, `SleepFiles`, `SleepNotifications`, `SleepLogging` | Builds each brand's `Theme`, resolves the file layout, seeds `SampleNights`, schedules `StartNotification`. A brand without Apple Health gets no stages card and no Health onboarding page, decided by the shared content's optional values |

Local work: `tuist generate` builds against `../SleepGuardShared`. `TUIST_SHARED_RELEASE=1 tuist generate` builds the pinned release, as CI does.

### One schema, each app's own access

Since 0.36.0 both apps store `SleepStore`'s records: event categories and intensities as raw strings (a value written by a newer version reads safely), no unique constraints, and a stored summary stamped with the formula's version, so lists never load events. Each app keeps its own access: SleepGuard reads with `@Query` on the main context and writes only through `SessionCommitter`; UIKitWay keeps the records inside its repository actor and hands out `Night` values. A breaking schema change is a new `SleepStoreSchema` version with a migration stage, and both apps take it.

---

## Versioning and releases

Apps depend on an **exact** released version:

```swift
.package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.37.0")
```

Exact pins make a shared change an explicit decision in each app: a release reaches an app only when that app bumps to it and its own tests pass. 37 releases so far (0.1.0 → 0.37.0): one per migrated concern, then the behaviour both apps had copied (0.32.0–0.36.0) and explicit imports (0.37.0).

**Releasing a change:**
1. Here: change, run `sh scripts/run-tests.sh`, commit, push. CI runs this repo's tests and builds SleepGuard and every UIKitWay brand against the commit.
2. Tag: `git tag -a <version> -m "What changed" && git push origin <version>`. Semantic versioning; while on 0.x, bump the minor for anything an app must adapt to.
3. In each app: `sh scripts/bump-shared.sh <version>` (rewrites every pin, SleepGuard's project included, and resolves), run all its tests, commit the manifests and lockfiles.

**Day to day:** both apps can build against the local checkout instead (above), so a change here and its use in an app are developed together and released afterwards.

**Stored types:** `RecordingGap`, `SleepStageSegment`, `SnoreBurst` and the enums' raw values are stored inside `SleepStore`'s records (and the checkpoint file). Changing their stored properties or raw values is a schema change for both apps, and is treated as one.

---

## Tests and CI

**335 Swift Testing tests.** `sh scripts/run-tests.sh` runs them all (after failing on any `@_exported import`):

| Target | Tests | Runs on | Covers |
|---|---:|---|---|
| `SleepCoreTests` | 241 | macOS (`swift test`) | Every rule: score and its golden, night metrics, episodes, statistics, playback, interrupter, briefing, report, storage plan and sweep, live classification, the decimator, sample nights, stored-value fixtures, and detection against replay goldens from a real night |
| `SleepStoreTests` | 6 | macOS | Records round-trip with events in order, unknown raw values, the summary stamped and stale, events replaced and cascaded, a broken store kept and backed up |
| `SleepFilesTests`, `SleepSettingsTests`, `SleepHealthKitTests`, `SleepNotificationsTests` | 18 | macOS | The file layout and files, the checkpoint format (spectrum included), settings, the Health sample, the start notification |
| `SleepAudioKitTests` | 24 | iOS Simulator | Levels, spectral score and the FFT gate, clip writing and compression, playback, waveform, clip spectrum and extraction, melody files, on generated tones |
| `SleepGuardContentKitTests` | 32 | iOS Simulator | Every screen's content rendered in two themes; briefing text mapping; the PDF has one page per page of rows |
| `SleepGuardDesignKitTests` | 12 | iOS Simulator | Every component rendered in two themes; a theme change changes the output |
| `SleepStringsTests` | 2 | iOS Simulator | The catalog loads |

Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR=/some/dir` to keep the rendered PNGs for review. `ImageRenderer` can't draw UIKit-backed views (`List`, `ScrollView` contents, `Toggle`, segmented and wheel `Picker`), so tests render the part inside them, and the apps' own tests check the rest.

**CI** (`.github/workflows/tests.yml`, every push to `main` and every PR):

| Job | Checks |
|---|---|
| `core` | No `@_exported import`; SleepCore (with the replay goldens), store, files, settings, HealthKit and notification tests on macOS |
| `ui` | `Strings.swift` matches the catalog; strings, melodies, design kit, content kit and audio kit tests on the simulator |
| `sleepguard` | Checks out SleepGuard next to this commit and builds it through a throwaway workspace that overrides its pin with this commit, so a breaking change fails here, before a release; warns about release skew |
| `uikitway` | Checks out SleepGuardUIKitWay, generates it in local mode against this commit, and builds every brand |

---

## Strings

1. Add entries to `Sources/SleepStrings/Resources/Strings.txt` (`key`, `key = value` or `"key" = "value"`), or edit `Localizable.xcstrings` directly with `"extractionState": "manual"`.
2. Run `python3 scripts/generate-xcstrings.py` (merges `Strings.txt`, then regenerates `Strings.swift`) or `python3 scripts/generate-strings.py` (regenerates only).
3. Never edit `Sources/SleepStrings/Strings.swift` by hand. CI fails if it doesn't match the catalog.

Keys are dot-separated by context (`session.summary.title`). Both apps reach strings only through `Strings.`; each app's CI rejects user-facing literals.
