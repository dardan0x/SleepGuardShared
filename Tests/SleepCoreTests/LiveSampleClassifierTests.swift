import Foundation
import Testing
@testable import SleepCore

/// One reading to the engine's input, the same in every app.
struct LiveSampleClassifierTests {
  private func reading(db: Float, peak: Float? = nil, snore: Float = 0, speech: Float = 0) -> LiveSampleClassifier.Reading {
    .init(db: db, peakDB: peak, spectralScore: 0.3, snoreConfidence: snore, speechConfidence: speech)
  }

  @Test func theSnoreVerdictUsesThePeakAndThePreset() {
    let classifier = LiveSampleClassifier(sensitivity: .medium)
    let input = classifier.input(for: reading(db: -60, peak: -25, snore: 0.6), isMelodyPlaying: false)
    #expect(input.snoreState == SnoreClassifier.preset(.medium).classify(db: -25, snoreConfidence: 0.6))
    #expect(input.snoreState != .none)
    #expect(input.db == -60 && input.spectralScore == 0.3) // passed through for the averages
  }

  @Test func withoutAPeakTheRMSLevelIsUsed() {
    let classifier = LiveSampleClassifier(sensitivity: .medium)
    let input = classifier.input(for: reading(db: -25, snore: 0.6), isMelodyPlaying: false)
    #expect(input.snoreState == SnoreClassifier.preset(.medium).classify(db: -25, snoreConfidence: 0.6))
  }

  @Test func speechUsesTheRMSLevel() {
    let classifier = LiveSampleClassifier(sensitivity: .medium)
    #expect(classifier.input(for: reading(db: -40, speech: 0.8), isMelodyPlaying: false).isSpeech)
    #expect(!classifier.input(for: reading(db: -70, speech: 0.8), isMelodyPlaying: false).isSpeech)
  }

  @Test func aNewSensitivityAppliesFromTheNextReading() {
    var classifier = LiveSampleClassifier(sensitivity: .low)
    classifier.update(sensitivity: .high)
    #expect(classifier.snore == .preset(.high))
    #expect(classifier.input(for: reading(db: -50), isMelodyPlaying: true).isMelodyPlaying)
  }
}

/// A capture sample reaches the rules unchanged.
struct CaptureSampleTests {
  @Test func aSampleIsItsReading() {
    let sample = CaptureSample(time: .now, db: -30, peakDB: -20, spectralScore: 0.4, snoreConfidence: 0.7, speechConfidence: 0.1)
    let reading = sample.reading
    #expect(reading.db == -30 && reading.peakDB == -20 && reading.spectralScore == 0.4)
    #expect(reading.snoreConfidence == 0.7 && reading.speechConfidence == 0.1)
  }
}
