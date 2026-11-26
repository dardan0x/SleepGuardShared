# SleepGuardShared

The architecture-independent core of SleepGuard: domain model and rules, localization, design system and screen content, as one versioned Swift package. It is consumed by two apps with deliberately different architectures:

- [**SleepGuard**](https://github.com/dardan0x/SleepGuard): SwiftUI, MV, SwiftData.
- [**SleepGuardUIKitWay**](https://github.com/dardan0x/SleepGuardUIKitWay): a UIKit shell with coordinators, a hexagonal core, and four white-label brands.

![Swift](https://img.shields.io/badge/Swift-6.2%20%C2%B7%20strict%20concurrency-orange)
![Platforms](https://img.shields.io/badge/iOS%2017%20%C2%B7%20watchOS%2010%20%C2%B7%20macOS%2014-blue)
![Tests](https://img.shields.io/badge/tests-251-brightgreen)
![Dependencies](https://img.shields.io/badge/third--party%20dependencies-0-lightgrey)

Reference material (every product, each app's integration module by module, versioning, tests) is in [docs/ARCHITECTURE_OVERVIEW.md](docs/ARCHITECTURE_OVERVIEW.md).

---

## Context

SleepGuard began as a single SwiftUI app. The goal of the second app was to build the same product on a UIKit-first architecture, the shape most large iOS codebases have, and compare the two honestly. That only works if both apps produce identical results: the same detected events from the same audio, the same score, the same screens.

The boundary is **behaviour versus composition**. Anything that can be computed or drawn from plain values is shared. Persistence, dependency injection, navigation, loading and lifecycle stay in each app, because that is the architecture being compared.

The extraction was incremental: 27 releases, each moving one concern (rules, then strings, then the design system, then screen content), with SleepGuard's test suite green on every release.

---

## Modules

```
SleepGuardContentKit        SwiftUI      Screen content: values, closures and view-builder slots in
└─► SleepGuardDesignKit     SwiftUI      Theme (environment value), stateless components
    ├─► SleepStrings        Foundation   String catalog, generated accessor
    └─► SleepCore           Foundation   Domain values, rules, detection actor

SleepMelodies               Foundation   Bundled audio, keyed by SleepCore's Melody
└─► SleepCore
```

| Module | Responsibility | Invariants |
|---|---|---|
| `SleepCore` | Domain values (`Night`, `NightEvent`, `NightSummary`, …) and pure functions over them: score, episodes, stage analysis, statistics, playback sequencing, briefing, report. The detection state machine and its actor | Foundation only. No persistence, clock, randomness or global state. All types `Sendable`. Tested on macOS |
| `SleepStrings` | `Localizable.xcstrings` and the generated `Strings` enum | Generated; CI fails on drift |
| `SleepMelodies` | Built-in melody resources | Resources only |
| `SleepGuardDesignKit` | `Theme` (palette, typography, radii) via `@Environment(\.theme)`; components initialised with values | No services, DI or persistence types. Every visual constant comes from `Theme` |
| `SleepGuardContentKit` | One loaded layout per screen | No loading, navigation or data access. Transient view state only |

---

## Dependency graph across the three repos

The shared package depends on nothing outside Apple's SDKs. Each app module imports the narrowest shared product it needs (from the manifests):

| Layer | SleepGuard | SleepGuardUIKitWay |
|---|---|---|
| Domain and storage | `Models` → SleepCore | `SleepDomain` → SleepCore<br>`SleepPersistence`, `SleepHealth` → SleepDomain, SleepCore |
| Audio and detection | `AudioEngine` → SleepCore<br>`Env` → SleepCore, SleepMelodies | `SleepAudio` → SleepDomain, SleepCore, SleepMelodies |
| Presentation infrastructure | `DesignSystem` → DesignKit, ContentKit, SleepStrings, SleepCore (and re-exports the kits) | `ScreenKit` → DesignKit |
| Screens | Feature packages → `DesignSystem` (for the kits), SleepCore | Feature modules → ContentKit, SleepCore, `SleepDomain` |
| Composition root | App target | `AppShell` → DesignKit, SleepCore (+ every app module); brand targets → DesignKit |

Two consequences:
- **UIKitWay's domain is written in SleepCore types.** `SleepDomain` adds ports and use cases, not a parallel model.
- **SleepGuard's domain maps into them.** `Models` keeps its SwiftData schema and maps each session to `Night` at the boundary.

---

## How each app binds to it

### Package resolution

Both apps pin an exact release and can override it with a local checkout. Because the override keeps the same package identity, no manifest changes between modes.

| | Release (CI, reproducible) | Local (day-to-day) |
|---|---|---|
| **SleepGuard** | `SleepGuard.xcodeproj` and every package manifest: `.package(url: …, exact: "0.27.0")` | `SleepGuard.xcworkspace` adds `../SleepGuardShared` as a local package. SwiftPM resolves the identity to the local copy |
| **SleepGuardUIKitWay** | `TUIST_SHARED_RELEASE=1 tuist generate`: `Project.swift` declares `.remote(…, .exact(version))` | `tuist generate` declares `.local(path: "../SleepGuardShared")` |

A shared change and its adoption are developed together locally, then released and pinned. `scripts/bump-shared.sh <version>` in each app moves every pin to the new release and re-resolves.

### Runtime seams

There are four seams. Each one is a type in this package, not a protocol either app has to implement:

| Seam | Type | SleepGuard | SleepGuardUIKitWay |
|---|---|---|---|
| **Domain values** | `Night`, `NightSummary` | `SleepSession+Night` maps the `@Model`. The score is cached on the model, stamped with `SleepScoreCacheVersion` | The persistence adapter maps its records behind `SessionRepository`. Use cases work on `Night` directly |
| **Detection** | `DetectionEngine` (actor) | `RealtimeDetectionTracker` streams timestamped messages in and performs outputs on the main actor | `RecordingSession` (domain actor) streams in and applies outputs to a checkpointed draft |
| **Theme** | `Theme`, `\.theme` | `AppTheme` from `Theme.sleepGuard`, set once at the app root | `BrandConfiguration.theme`, set by `HostingScreen` on each `UIHostingController` |
| **Screen content** | `*Content` views | A SwiftUI container owns loading and `ViewState`; closures set sheet state or call `RouterPath` | A hosted screen owns loading and `ViewState`; closures forward to `Routes`, which a coordinator implements |

The last seam is where the two architectures meet. The same content, hosted by each app:

```swift
// SleepGuard: container view; navigation is local state.
NightDetailContent(
  night: night, summary: night.summary(using: appConfig.sleepScoreConfig),
  filters: model.filters, filter: $model.selectedFilter,
  onPlay: { row in activeSheet = .player(initialEvent: model.event(for: row)) },
  onShowAll: { _ in activeSheet = .events },
  stages: { SleepStagesSection(session: session, scoreConfig: appConfig.sleepScoreConfig) },
  footer: { ShortEventsButton(count: model.shortEvents.count) { activeSheet = .shortEventsPlayer } })

// SleepGuardUIKitWay: hosted screen; intent leaves through Routes to a coordinator.
NightDetailContent(
  night: night, summary: detail.summary, filters: EventFilter.options(for: night.events), filter: $filter,
  onPlay: { row in routes.playEvents(row.playback(in: night.events), row.id) },
  onShowAll: { rows in routes.showAllEvents(rows, night.events) },
  stages: { /* SleepStagesCard when the brand has Apple Health */ },
  footer: { EmptyView() })
```

---

## Business logic: extraction and testing

### How a rule leaves an app

Every rule followed the same five-step path out of SleepGuard. The app's behaviour was preserved at each step.

1. **Characterise.** The existing behaviour is pinned by SleepGuard's own tests before anything moves.
2. **Separate the rule from its inputs.** Find what the rule actually reads (a session's events, the current time, a random draw) and turn each into a parameter. SwiftData models, `Date()`, `randomElement()` and `UserDefaults` become plain values.
3. **Move it as a pure function over `SleepCore` values,** with the characterisation tests rewritten against values instead of models or text.
4. **Map at the app's edge.** The app converts its storage to `Night` / `NightSummary` and calls the rule. Parity tests in the app check that the numbers didn't change.
5. **Release, bump, delete.** Tag a release, bump the app, delete the app's copy.

The rules end up as functions whose signatures state every input:

```swift
SleepScore.compute(_ inputs: SleepInputs, config: SleepScoreConfig) -> Int
NightDashboard.make(from nights: [NightSummary], now: Date, calendar: Calendar) -> NightDashboard?
StoragePlan.make(nights: [Night], now: Date, maxDays: Int?, maxMB: Int?) -> StoragePlan
BriefingEngine.make(nights:profile:logs:now:calendar:) -> Briefing
BriefingSchedule.isDue(latest: NightSummary?, lastShown: Date?, now: Date, calendar: Calendar) -> Bool
```

Moving a rule tends to expose defects its old surroundings hid. The briefing engine is an example. In SleepGuard it was 531 lines that returned localized strings and chose its content with `randomElement()`, so two of its tests could only assert `!= nil`. It also saved the four "positive" survey answers as an empty log. Extracted, it returns a `Briefing` value, chooses its variant from a seed derived from the night, and models every survey answer. Every assertion is now exact, and the fix shipped to both apps in one release.

### What gets tested, where

Each layer is tested at its own level, so the suites don't overlap:

| Layer | What the tests check | How | Count |
|---|---|---|---:|
| `SleepCore` rules | Score, episodes, stage analysis, statistics, playback sequencing, interrupter gaps, storage plan, briefing, report | `swift test` on macOS. No simulator, no fixtures beyond values; the suite runs in seconds | 208 |
| Detection | The state machine's decisions over time | Unit tests on the state machine and the actor, plus **replay goldens**: four excerpts of a real night's samples (`loud-onset`, `sustained-snoring`, `sparse-snores`, `short-bursts-and-quiet`) and the exact decisions recorded for them | (in the 208) |
| Copy | Values to localized text (`BriefingText`, labels, formats) | Each rule output mapped to the expected `Strings` entry | (in ContentKit) |
| Components and screens | Every component and every screen's content renders, in two themes, and the theme changes the output | `ImageRenderer` on the simulator; PNGs kept for review on request | 39 |
| Report | The PDF has one page per page of rows | Rendered and parsed back with `CGPDFDocument` | (in ContentKit) |
| **SleepGuard** | The `@Model` → `Night` mapping (parity), the score cache, state owners, services | In-memory SwiftData, fakes for every service | 211 |
| **SleepGuardUIKitWay** | Use cases against fake ports, adapters against real stores, coordinators against a navigator spy, each brand's app | Domain on macOS; flows with no UI | 210 + 9 per brand |

Neither app re-tests a rule. When the score changes, one suite here changes, and both apps' suites confirm that their mappings and composition still hold against the new release.

### What this buys

- **One fix, every app.** A defect in a rule is reproduced as a value-level test here, fixed once, and reaches every app through a version bump.
- **Reuse without adaptation.** A new consumer gets the rules, copy, theme and screens by mapping its storage to `Night` and implementing the closures. UIKitWay's fourth brand needed no domain or screen code.
- **Fast feedback where it matters.** The logic most likely to regress (detection, scoring) runs without a simulator, so it runs on every change.
- **Behaviour changes are deliberate.** A change to detection output fails the goldens until someone re-records them on purpose and explains the diff in review.

### Limits

- Render tests prove that a screen draws in every theme and that themes reach it. They are not pixel snapshots, and `ImageRenderer` can't draw UIKit-backed views (`List`, `Toggle`, some `Picker` styles). Those parts are checked in the apps.
- Each app's mapping layer is its own responsibility. The shared suite can't see a field an app forgets to map, so each app's parity tests do that job.
- Live audio, permissions and HealthKit are outside the package. The detection pipeline is verified here from samples onward; the microphone end needs a device.

---

## Design decisions

- **Share values, not persistence.** A shared `@Model` would couple both apps' schemas, migration histories and actor isolation. Mapping at each edge costs one adapter per app, and parity tests cover it.
- **Detection as a single ordered stream.** Samples, interrupter start and stop, settings changes and session end are timestamped messages into one actor. No side path mutates detection state. Golden outputs recorded from a real night pin the behaviour.
- **Variation through optionals and slots, never flags.** Content takes `nil` to omit a section, or a view-builder slot for app-specific UI. A brand without HealthKit loses the stages card and the Health onboarding page without the package knowing brands exist.
- **Exact pins, verified from both sides.** A release reaches an app only through an explicit bump that passes that app's suite. Before release, this repo's CI builds SleepGuard and every UIKitWay brand against the candidate commit, and warns when an app's pin is more than two minor releases behind.

ADRs live with the consumers: SleepGuard [0004](https://github.com/dardan0x/SleepGuard/blob/main/docs/adr/0004-shared-repo.md), [0005](https://github.com/dardan0x/SleepGuard/blob/main/docs/adr/0005-shared-design-kit.md), [0006](https://github.com/dardan0x/SleepGuard/blob/main/docs/adr/0006-shared-screen-content.md); UIKitWay [0004](https://github.com/dardan0x/SleepGuardUIKitWay/blob/main/docs/adr/0004-shared-repo.md), [0005](https://github.com/dardan0x/SleepGuardUIKitWay/blob/main/docs/adr/0005-shared-screen-content.md).

---

## Working on it

| Task | How |
|---|---|
| Test | `sh scripts/run-tests.sh`: SleepCore on macOS (229, including replay goldens, stored-value fixtures and the score golden); the kits render every component and screen in two themes on the simulator (39); strings and melodies (4) |
| Release | Commit, push, `git tag -a 0.28.0 -m "…" && git push origin 0.28.0`. Then, in each app: `sh scripts/bump-shared.sh 0.28.0` and that app's tests |
| Add a string | Add it to `Sources/SleepStrings/Resources/Strings.txt`, then run `python3 scripts/generate-xcstrings.py` |
| Change detection | Re-record the goldens deliberately with `sh scripts/record-replay-goldens.sh` and explain the diff |
| Change a stored value | Types marked `StoredValue` are persisted by the apps: add properties only (optional or decoded with a default), never rename or remove a property or raw value, and add a `Tests/SleepCoreTests/Fixtures/StoredValues/<version>/` fixture |

### Release policy

- **Patch** (x.y.**z**): additive and behaviour-neutral only: new strings, new public pieces, fixes that change no output.
- **Minor** (x.**y**.0): anything an app or a user can notice: a score coefficient or formula change (bump `SleepScore.formulaVersion` for code changes; `ScoreGoldenTests` fails without it), a detection change (goldens re-recorded), a new case in an enum the apps switch over, a stored-shape change.
- **Renames and removals** of public API go through one minor release as `@available(*, deprecated, renamed:)` (or `message:`) first, and are removed in the next minor. Example: `Night.minimumSaveDuration` was deprecated in 0.30.0 in favour of `SaveRules` and removed in 0.31.0.
- **Skew** between the apps is allowed, but CI warns beyond two minor releases; bump with each app's `bump-shared.sh`.

Ground rules: Swift 6 strict concurrency; `Sendable` values; Foundation-only `SleepCore`; values in, closures out; every visual constant from `Theme`; no app-specific branches.
