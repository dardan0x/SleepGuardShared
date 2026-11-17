import Foundation

/// What a night adds up to: snoring time, events, stages, score. Pure functions
/// of the night's values; the formula itself is `SleepScore`.
public extension Night {
  /// Snoring time used by the score: snoring events' spans, plus recording gaps
  /// where snoring resumed if events don't already span them.
  ///
  /// A melody pause doesn't prove snoring continued, so only gaps marked
  /// `snoringResumed` count. Events recorded by current detection span their
  /// gaps; a gap no event covers (older recordings) is added on top.
  var snoringDuration: TimeInterval {
    let snoring = events.filter { $0.category == .snoring }
    let eventTime = snoring.reduce(0) { $0 + $1.duration }
    let countableGaps = recordingGaps.filter(\.snoringResumed)
    let gapTime = countableGaps.reduce(0) { $0 + $1.duration }
    guard gapTime > 0 else { return eventTime }

    let hasUncoveredGap = countableGaps.contains { gap in
      let gapStart = start.addingTimeInterval(gap.startOffset)
      let gapEnd = gapStart.addingTimeInterval(gap.duration)
      return !snoring.contains { $0.start <= gapStart && $0.end >= gapEnd }
    }
    return eventTime + (hasUncoveredGap ? gapTime : 0)
  }

  /// Total recording-gap time (microphone paused).
  var gapsDuration: TimeInterval {
    recordingGaps.reduce(0) { $0 + $1.duration }
  }

  var sleepTalkingEvents: [NightEvent] {
    events.filter { $0.category == .sleepTalking }
  }

  var sleepTalkingDuration: TimeInterval {
    sleepTalkingEvents.reduce(0) { $0 + $1.duration }
  }

  var displayableEpisodes: [NightEpisode] {
    SnoringEpisodes.displayable(in: events)
  }

  /// Displayable snoring episodes plus every non-snoring event.
  var eventCount: Int {
    displayableEpisodes.count + events.filter { $0.category != .snoring }.count
  }

  /// Stage percentages, or `nil` without stage data.
  var stageStats: StageStats? {
    StageStats.make(from: sleepStages)
  }

  /// The score formula's inputs. Intensity uses measured sound (bursts), not
  /// event spans: there is no intensity data during melody gaps.
  var scoreInputs: SleepInputs {
    var inputs = SleepInputs(
      totalDuration: duration,
      snoringDuration: snoringDuration,
      snoringEpisodeCount: displayableEpisodes.count,
      sleepTalkingCount: sleepTalkingEvents.count,
      sleepTalkingDuration: sleepTalkingDuration,
      stages: stageStats)
    for event in events where event.category == .snoring {
      switch event.intensity {
      case .quiet: inputs.quietSnoring += event.measuredDuration
      case .light: inputs.lightSnoring += event.measuredDuration
      case .loud: inputs.loudSnoring += event.measuredDuration
      case .epic: inputs.epicSnoring += event.measuredDuration
      }
    }
    return inputs
  }

  func score(using config: SleepScoreConfig = .default) -> Int {
    SleepScore.compute(scoreInputs, config: config)
  }

  /// The row a list shows, computed once when the night is saved.
  func summary(using config: SleepScoreConfig = .default) -> NightSummary {
    NightSummary(
      id: id, start: start, end: end,
      score: score(using: config), snoringDuration: snoringDuration, eventCount: eventCount,
      loudestIntensity: loudestIntensity)
  }

  /// The loudest intensity of any event (every category, as SleepGuard's
  /// statistics count it); `nil` without events.
  var loudestIntensity: SnoreIntensity? {
    events.map(\.intensity).max()
  }
}
