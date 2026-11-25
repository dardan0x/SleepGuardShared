import Foundation
import Testing
@testable import SleepCore

/// Every released shape of the values the apps store must keep decoding
/// (`StoredValue`). A rename, a removed property or a new required one fails
/// here, before a tag reaches an app's users.
struct StoredValuesTests {
  private func decode<T: Decodable>(_: T.Type, _ name: String, version: String) throws -> T {
    let url = try #require(Bundle.module.url(
      forResource: name, withExtension: "json", subdirectory: "Fixtures/StoredValues/\(version)"))
    return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
  }

  @Test func gapsFromBeforeKindsDecodeAsMelodyGaps() throws {
    let gaps = try decode([RecordingGap].self, "recording-gaps", version: "0.29.0")
    #expect(gaps == [
      RecordingGap(startOffset: 600, duration: 45, snoringResumed: true, kind: .melody),
      RecordingGap(startOffset: 1200, duration: 30, snoringResumed: false, kind: .melody),
      // Older still: no `snoringResumed` either.
      RecordingGap(startOffset: 1800, duration: 20, snoringResumed: true, kind: .melody),
    ])
  }

  @Test func gapKindsDecodeAndAnUnknownOneFallsBackToMelody() throws {
    let gaps = try decode([RecordingGap].self, "recording-gaps", version: "0.30.0")
    #expect(gaps.map(\.kind) == [.melody, .interruption, .melody])
  }

  @Test func gapsRoundTrip() throws {
    let gaps = [RecordingGap(startOffset: 1, duration: 2, snoringResumed: false, kind: .interruption)]
    #expect(try JSONDecoder().decode([RecordingGap].self, from: JSONEncoder().encode(gaps)) == gaps)
  }

  @Test func sleepStageSegmentsDecode() throws {
    let segments = try decode([SleepStageSegment].self, "sleep-stage-segments", version: "0.29.0")
    #expect(segments.map(\.stage) == [.deep, .rem, .light, .awake])
    #expect(segments.map(\.duration) == [1800, 900, 3600, 300])
  }

  @Test func snoreBurstsDecode() throws {
    let bursts = try decode([SnoreBurst].self, "snore-bursts", version: "0.29.0")
    #expect(bursts == [SnoreBurst(startOffset: 0, endOffset: 2.5), SnoreBurst(startOffset: 4, endOffset: 7.25)])
  }

  @Test func rawLogSamplesDecodeWithAndWithoutTheLaterFields() throws {
    let samples = try decode([SnoreSample].self, "snore-samples", version: "0.29.0")
    #expect(samples[0].peakDB == -20 && samples[0].speechConfidence == 0.1 && samples[0].state == .loud)
    #expect(samples[1].peakDB == nil && samples[1].speechConfidence == nil && samples[1].state == DetectionState.none)
  }

  /// Raw values are stored as-is (SwiftData string columns, preferences).
  @Test func everyStoredRawValueStillDecodes() throws {
    let raw = try decode([String: [String]].self, "raw-values", version: "0.29.0")
    #expect(try #require(raw["sleepStage"]).compactMap(SleepStage.init(rawValue:)).count == 4)
    #expect(try #require(raw["snoreIntensity"]).compactMap(SnoreIntensity.init(rawValue:)).count == 4)
    #expect(try #require(raw["soundCategory"]).compactMap(SoundCategory.init(rawValue:)).count == 5)
    #expect(try #require(raw["detectionState"]).compactMap(DetectionState.init(rawValue:)).count == 5)
    #expect(try #require(raw["detectionSensitivity"]).compactMap(DetectionSensitivity.init(rawValue:)).count == 3)
    #expect(try #require(raw["snoreInterrupterMode"]).compactMap(SnoreInterrupterMode.init(rawValue:)).count == 6)
  }
}
