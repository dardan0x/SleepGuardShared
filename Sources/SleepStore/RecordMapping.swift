import Foundation
public import SleepCore
public import SwiftData

/// Records ↔ SleepCore's night values. Both apps compute everything from the
/// values (`Night`, `NightSummary`), so the numbers come out the same.
public extension NightRecord {
  /// Reads `events`. They come back in time order: SwiftData doesn't keep
  /// relationship order.
  var night: Night {
    Night(
      id: id, start: start, end: max(end, start), averageDB: averageDB, peakDB: peakDB,
      events: events.map(\.event).sorted { $0.start < $1.start },
      recordingGaps: recordingGaps, sleepStages: sleepStages, endReason: endReason)
  }

  /// The stored summary; doesn't read `events`.
  var summary: NightSummary {
    NightSummary(
      id: id, start: start, end: max(end, start), score: score, snoringDuration: snoringDuration,
      eventCount: eventCount, loudestIntensity: loudestIntensity)
  }

  /// Everything but the events and the summary.
  func update(from night: Night) {
    start = night.start
    end = night.end
    averageDB = night.averageDB
    peakDB = night.peakDB
    endReason = night.endReason
    recordingGaps = night.recordingGaps
    sleepStages = night.sleepStages
  }

  func update(from summary: NightSummary, scoreVersion: String) {
    score = summary.score
    snoringDuration = summary.snoringDuration
    eventCount = summary.eventCount
    loudestIntensityRawValue = summary.loudestIntensity?.rawValue
    self.scoreVersion = scoreVersion
  }

  /// Recomputes the stored summary from the events with `config` and stamps
  /// its version. Reads `events`. The caller saves.
  func refreshSummary(using config: SleepScoreConfig) {
    update(from: night.summary(using: config), scoreVersion: SleepScore.cacheVersion(for: config))
  }

  /// Whether the summary is missing or was made by another formula/config.
  /// Doesn't read `events`.
  func hasStaleSummary(for config: SleepScoreConfig) -> Bool {
    scoreVersion != SleepScore.cacheVersion(for: config)
  }

  /// A record (in no context yet) with its events, from a night value: a
  /// recovered checkpoint, a sample night, or a night being saved.
  static func make(from night: Night) -> NightRecord {
    let record = NightRecord(id: night.id)
    record.update(from: night)
    record.events = night.events.map(NightEventRecord.make(from:))
    return record
  }

  /// Replaces the events with `events` (a saved night's events are a value).
  func replaceEvents(with events: [NightEvent], in context: ModelContext) {
    for old in self.events {
      context.delete(old)
    }
    self.events = events.map { event in
      let record = NightEventRecord.make(from: event)
      context.insert(record)
      return record
    }
  }
}

public extension NightEventRecord {
  var event: NightEvent {
    NightEvent(
      id: id, start: start, duration: max(0, duration), category: category, intensity: intensity,
      averageDB: averageDB, peakDB: peakDB, averageConfidence: averageConfidence, bursts: bursts,
      clipFileName: clipFileName, averageSpectralScore: averageSpectralScore,
      dominantFrequency: dominantFrequency, spectralCentroid: spectralCentroid, lowFreqRatio: lowFreqRatio)
  }

  func update(from event: NightEvent) {
    start = event.start
    duration = event.duration
    category = event.category
    intensity = event.intensity
    averageDB = event.averageDB
    peakDB = event.peakDB
    averageConfidence = event.averageConfidence
    averageSpectralScore = event.averageSpectralScore
    dominantFrequency = event.dominantFrequency
    spectralCentroid = event.spectralCentroid
    lowFreqRatio = event.lowFreqRatio
    bursts = event.bursts
    clipFileName = event.clipFileName
  }

  static func make(from event: NightEvent) -> NightEventRecord {
    let record = NightEventRecord(id: event.id)
    record.update(from: event)
    return record
  }
}
