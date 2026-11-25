import Foundation
import Testing
@testable import SleepCore

/// A call or another app interrupts capture: the paused span is an
/// interruption gap, open events end, and the score leaves the span out of
/// its percentages (formula version 2).
struct CaptureInterruptionTests {
  private let t0 = Date(timeIntervalSinceReferenceDate: 0)
  private let snoring = DetectionInput(db: -35, snoreConfidence: 0.6, snoreState: .light)
  private static let settings = DetectionStateMachine.Settings(
    minEventDuration: 1, highConfidenceGate: 0.55, detectSleepTalking: false)

  private func machine() -> DetectionStateMachine {
    DetectionStateMachine(settings: Self.settings)
  }

  @Test func resumeEmitsTheInterruptionGap() {
    var machine = machine()
    #expect(machine.captureDidPause(at: t0).isEmpty)
    #expect(machine.captureDidResume(at: t0.addingTimeInterval(90)) == [.interruptionGap(start: t0, duration: 90)])
    #expect(machine.captureDidResume(at: t0.addingTimeInterval(95)).isEmpty)
  }

  @Test func anOpenEventEndsWhenCapturePauses() {
    var machine = machine()
    var time = t0
    while time < t0.addingTimeInterval(3) {
      _ = machine.ingest(snoring, at: time)
      time = time.addingTimeInterval(0.05)
    }
    #expect(machine.hasActiveSnoreEvent)

    let outputs = machine.captureDidPause(at: t0.addingTimeInterval(4))

    #expect(!machine.hasActiveSnoreEvent)
    #expect(outputs.contains { if case .snoreEventFinalized = $0 { true } else { false } })
  }

  @Test func aNightEndingDuringAnInterruptionKeepsTheGap() {
    var machine = machine()
    _ = machine.captureDidPause(at: t0)
    #expect(machine.finalizeActiveEvents(at: t0.addingTimeInterval(60)) == [.interruptionGap(start: t0, duration: 60)])
  }

  @Test func theEngineCarriesCaptureMessagesInOrder() async {
    let engine = DetectionEngine(settings: Self.settings)
    let (stream, continuation) = DetectionEngine.makeStream()
    let recorder = BatchRecorder()
    let run = Task { await engine.run(stream) { await recorder.add($0); return [] } }
    continuation.yield(.captureDidPause(at: t0))
    continuation.yield(.captureDidResume(at: t0.addingTimeInterval(30)))
    continuation.finish()
    await run.value
    #expect(await recorder.batches.map(\.outputs) == [[.interruptionGap(start: t0, duration: 30)]])
  }

  // MARK: - Score

  @Test func interruptionTimeIsLeftOutOfTheSnoringPercentage() {
    // 8 h night, 48 min snoring. 4 h interrupted: 48 min of 4 h measured = 20%.
    let snoringEvent = Sample.event(at: 600, duration: 48 * 60)
    let interrupted = Sample.night(
      events: [snoringEvent],
      gaps: [RecordingGap(startOffset: 4 * 3600, duration: 4 * 3600, snoringResumed: false, kind: .interruption)])
    let uninterrupted = Sample.night(events: [snoringEvent])

    #expect(interrupted.scoreInputs.unmeasuredDuration == 4 * 3600)
    #expect(interrupted.score() < uninterrupted.score())
  }

  @Test func melodyGapsScoreAsBefore() {
    let melody = Sample.night(
      events: [Sample.event(at: 600)],
      gaps: [RecordingGap(startOffset: 3600, duration: 60, snoringResumed: true, kind: .melody)])
    #expect(melody.scoreInputs.unmeasuredDuration == 0)
    #expect(melody.melodyGapsDuration == 60 && melody.interruptionDuration == 0)
  }

  @Test func aSnoringResumedMarkSkipsALaterInterruption() {
    let gaps = [RecordingGap]()
      .adding(start: Sample.at(60), duration: 30, nightStart: Sample.start)
      .adding(start: Sample.at(600), duration: 90, nightStart: Sample.start, kind: .interruption)
      .markingLastSnoringResumed()
    #expect(gaps.map(\.snoringResumed) == [true, false])
  }

  @Test func aFullyInterruptedNightHasNoSnoringPenalty() {
    let inputs = SleepInputs(totalDuration: 3600, unmeasuredDuration: 3600, snoringDuration: 0)
    #expect(SleepScore.compute(inputs, config: .default) == SleepScore.compute(SleepInputs(totalDuration: 3600), config: .default))
  }
}

private actor BatchRecorder {
  private(set) var batches: [DetectionEngine.Batch] = []
  func add(_ batch: DetectionEngine.Batch) {
    batches.append(batch)
  }
}
