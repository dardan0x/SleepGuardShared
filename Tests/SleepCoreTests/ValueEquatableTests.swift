import Foundation
import Testing
@testable import SleepCore

/// Value types compare by value, so apps can compare whole sessions.
struct ValueEquatableTests {
  @Test func recordingGapsCompareEveryField() {
    let gap = RecordingGap(startOffset: 120, duration: 30, snoringResumed: true)
    #expect(gap == RecordingGap(startOffset: 120, duration: 30, snoringResumed: true))
    #expect(gap != RecordingGap(startOffset: 120, duration: 30, snoringResumed: false))
  }

  @Test func sleepStageSegmentsCompareEveryField() {
    let segment = SleepStageSegment(stage: .deep, startOffset: 0, duration: 600)
    #expect(segment == SleepStageSegment(stage: .deep, startOffset: 0, duration: 600))
    #expect(segment != SleepStageSegment(stage: .rem, startOffset: 0, duration: 600))
  }
}
