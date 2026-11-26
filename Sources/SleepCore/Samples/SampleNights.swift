import Foundation

/// Sample nights for Debug builds and previews, so screens have data before
/// anything is recorded. Generated from a fixed seed: the same nights, ids
/// included, on every run, every device and every app, which keeps
/// screenshots stable. Each app saves them its own way; `SleepAudioKit`
/// writes their clips.
public enum SampleNights {
  /// `count` nights, newest first, the newest starting the evening before `today`.
  public static func make(count: Int = 14, before today: Date = .now, calendar: Calendar = .current) -> [Night] {
    var random = SeededRandom(seed: 0x5EED)
    let midnight = calendar.startOfDay(for: today)
    return (1...count).map { daysBack in
      let evening = calendar.date(byAdding: .day, value: -daysBack, to: midnight) ?? midnight
      return night(starting: evening.addingTimeInterval(22.5 * 3600), index: daysBack, random: &random)
    }
  }

  // MARK: - Generation

  private static func night(starting base: Date, index: Int, random: inout SeededRandom) -> Night {
    let start = base.addingTimeInterval(Double.random(in: 0...5400, using: &random))
    let duration = Double.random(in: 5.5...9, using: &random) * 3600

    var events: [NightEvent] = []
    for _ in 0..<Int.random(in: 0...6, using: &random) {
      events += episode(at: Double.random(in: 1800...(duration - 3600), using: &random), from: start, random: &random)
    }
    for _ in 0..<Int.random(in: 0...3, using: &random) {
      events.append(NightEvent(
        id: random.uuid(),
        start: start.addingTimeInterval(Double.random(in: 600...(duration - 600), using: &random)),
        duration: Double.random(in: 5...20, using: &random),
        category: .sleepTalking, intensity: .quiet,
        averageDB: -48, peakDB: -38, averageConfidence: 0.7))
    }

    let gaps = random.chance(0.3)
      ? [RecordingGap(
        startOffset: Double.random(in: 3600...(duration - 3600), using: &random),
        duration: Double.random(in: 60...300, using: &random),
        snoringResumed: random.chance(0.5))]
      : []

    return Night(
      id: random.uuid(),
      start: start,
      end: start.addingTimeInterval(duration),
      averageDB: -46, peakDB: events.map(\.peakDB).max() ?? -40,
      events: events.sorted { $0.start < $1.start },
      recordingGaps: gaps,
      sleepStages: index % 3 == 0 ? [] : stages(lasting: duration),
      endReason: index == 5 ? .lowBattery : .stopped)
  }

  /// One to four snoring events a few minutes apart: one episode.
  private static func episode(at offset: TimeInterval, from start: Date, random: inout SeededRandom) -> [NightEvent] {
    var events: [NightEvent] = []
    var cursor = offset
    for _ in 0..<Int.random(in: 1...4, using: &random) {
      let duration = Double.random(in: 8...90, using: &random)
      let intensity: SnoreIntensity = [.quiet, .light, .light, .loud, .loud, .epic][Int.random(in: 0...5, using: &random)]
      let firstBurst = duration * Double.random(in: 0.3...0.6, using: &random)
      let id = random.uuid() // drawn where it always was, so the nights stay the same
      events.append(NightEvent(
        id: id,
        start: start.addingTimeInterval(cursor),
        duration: duration,
        intensity: intensity,
        averageDB: [-44, -36, -24, -14][intensity.rank],
        peakDB: [-36, -28, -16, -6][intensity.rank],
        averageConfidence: Double.random(in: 0.5...0.95, using: &random),
        bursts: [
          SnoreBurst(startOffset: 0, endOffset: firstBurst),
          SnoreBurst(startOffset: firstBurst + 2, endOffset: duration),
        ],
        clipFileName: "\(id.uuidString).m4a"))
      cursor += duration + Double.random(in: 30...200, using: &random)
    }
    return events
  }

  /// 90-minute cycles of light, deep, light, REM and a moment awake.
  private static func stages(lasting duration: TimeInterval) -> [SleepStageSegment] {
    let cycle: [(SleepStage, TimeInterval)] = [(.light, 30), (.deep, 20), (.light, 15), (.rem, 20), (.awake, 5)]
    var segments: [SleepStageSegment] = []
    var offset: TimeInterval = 0
    while offset < duration {
      for (stage, minutes) in cycle where offset < duration {
        let length = min(minutes * 60, duration - offset)
        segments.append(SleepStageSegment(stage: stage, startOffset: offset, duration: length))
        offset += length
      }
    }
    return segments
  }
}

/// A deterministic generator (64-bit LCG): the same sequence on every run.
public struct SeededRandom: RandomNumberGenerator, Sendable {
  private var state: UInt64

  public init(seed: UInt64) {
    state = seed
  }

  public mutating func next() -> UInt64 {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return state
  }

  public mutating func chance(_ probability: Double) -> Bool {
    Double.random(in: 0..<1, using: &self) < probability
  }

  public mutating func uuid() -> UUID {
    let a = next(), b = next()
    return withUnsafeBytes(of: (a, b)) { UUID(uuid: $0.load(as: uuid_t.self)) }
  }
}

public extension SampleNights {
  /// The longest sample clip. Longer events play their clip only (the
  /// player stops at the end of the file), which keeps seeding quick.
  static let maxClipSeconds: TimeInterval = 15

  /// Every sample clip to write: file name, length, intensity.
  static func clips(of nights: [Night]) -> [(name: String, seconds: TimeInterval, intensity: SnoreIntensity)] {
    nights.flatMap(\.events).compactMap { event in
      event.clipFileName.map { ($0, min(event.duration, maxClipSeconds), event.intensity) }
    }
  }

  /// Survey answers for about half the nights, from the same seed: a mix of
  /// better-night and worse-night chips.
  static func lifestyleLogs(for nights: [Night]) -> [LifestyleLog] {
    var random = SeededRandom(seed: 0x10F)
    return nights.compactMap { night in
      guard random.chance(0.5) else { return nil }
      let pool = random.chance(0.5) ? LifestyleChip.positive : LifestyleChip.negative
      let count = Int.random(in: 1...2, using: &random)
      return LifestyleLog(night: night.start, chips: Set(pool.shuffled(using: &random).prefix(count)))
    }
  }
}
