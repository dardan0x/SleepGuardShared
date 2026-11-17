import Foundation
import Testing
@testable import SleepCore

struct SnoreInterrupterModeTests {
  @Test func storedValuesReadBackAndUnknownIsOff() {
    #expect(SnoreInterrupterMode(stored: "fifteenSeconds") == .fifteenSeconds)
    #expect(SnoreInterrupterMode(stored: "never") == .never)
    #expect(SnoreInterrupterMode(stored: "loud") == .never)
    #expect(SnoreInterrupterMode(stored: nil) == .never)
  }

  @Test func durationsAndLooping() {
    #expect(SnoreInterrupterMode.fiveSeconds.playDuration == 5)
    #expect(SnoreInterrupterMode.sixtySeconds.playDuration == 60)
    #expect(SnoreInterrupterMode.always.playDuration == nil)
    #expect(SnoreInterrupterMode.always.loops)
    #expect(!SnoreInterrupterMode.thirtySeconds.loops)
    #expect(!SnoreInterrupterMode.never.isOn)
    #expect(SnoreInterrupterMode.always.isOn)
  }
}

struct MelodyTests {
  @Test func catalogIsSleepGuards() {
    #expect(Melody.builtIn.map(\.id) == Array(1...11))
    #expect(Set(Melody.builtIn.map(\.filename)).count == 11)
    #expect(Melody.builtIn.allSatisfy { !$0.isCustom })
  }

  @Test func resolveFindsBuiltInThenCustomThenDefault() {
    let mine = Melody(id: 100, filename: "custom_100.m4a", customName: "My Sound 1")
    #expect(Melody.resolve(id: 3, custom: [mine]).id == 3)
    #expect(Melody.resolve(id: 100, custom: [mine]) == mine)
    #expect(Melody.resolve(id: 101, custom: [mine]).id == Melody.defaultID)
    #expect(Melody.resolve(id: 0, custom: []).id == Melody.defaultID)
  }

  @Test func customRules() {
    let a = Melody(id: 100, filename: CustomMelodies.filename(id: 100), customName: "A")
    let b = Melody(id: 104, filename: CustomMelodies.filename(id: 104), customName: "B")
    #expect(a.filename == "custom_100.m4a")
    #expect(CustomMelodies.nextID(stored: 0, existing: []) == 100)
    #expect(CustomMelodies.nextID(stored: 102, existing: [a]) == 102)
    #expect(CustomMelodies.nextID(stored: 0, existing: [a, b]) == 105)
    #expect(CustomMelodies.nameNumber(existing: [a, b]) == 3)
  }
}

struct RecordingGapListTests {
  let start = Date(timeIntervalSince1970: 1_000)

  @Test func addingStoresTheOffset() {
    let gaps = [RecordingGap]().adding(start: start.addingTimeInterval(90), duration: 12, nightStart: start)
    #expect(gaps == [RecordingGap(startOffset: 90, duration: 12, snoringResumed: false)])
  }

  @Test func emptyOrEarlyGapsAreLeftOut() {
    #expect([RecordingGap]().adding(start: start, duration: 0, nightStart: start).isEmpty)
    #expect([RecordingGap]().adding(start: start.addingTimeInterval(-1), duration: 5, nightStart: start).isEmpty)
  }

  @Test func markingTouchesOnlyTheLatest() {
    let gaps = [RecordingGap]()
      .adding(start: start.addingTimeInterval(10), duration: 5, nightStart: start)
      .adding(start: start.addingTimeInterval(60), duration: 5, nightStart: start)
      .markingLastSnoringResumed()
    #expect(gaps.map(\.snoringResumed) == [false, true])
    #expect([RecordingGap]().markingLastSnoringResumed().isEmpty)
  }
}
