import Foundation
import Testing
@testable import SleepCore

struct NightReportTests {
  let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  func event(_ minute: Double, _ category: SoundCategory, _ intensity: SnoreIntensity = .light) -> NightEvent {
    NightEvent(start: start.addingTimeInterval(minute * 60), duration: 30, category: category, intensity: intensity)
  }

  @Test(arguments: [(95, NightReport.Rating.excellent), (80, .excellent), (79, .fair), (50, .fair), (49, .poor)])
  func ratingBands(score: Int, rating: NightReport.Rating) {
    #expect(NightReport.Rating(score: score) == rating)
  }

  @Test func rowsAreInTimeOrderWithTheirKind() {
    let night = Night(
      start: start, end: start.addingTimeInterval(8 * 3600),
      events: [event(90, .sleepTalking), event(10, .snoring, .loud), event(50, .coughing)])
    let report = NightReport(night: night)
    #expect(report.rows.map(\.kind) == [.snoring, .noise, .sleepTalking])
    #expect(report.rows.first?.intensity == .loud)
    #expect(report.sleepTalking?.count == 1)
    #expect(report.stages == nil)
    #expect(report.duration == 8 * 3600)
  }

  @Test func aQuietNightHasNoSleepTalking() {
    let report = NightReport(night: Night(start: start, end: start.addingTimeInterval(3600)))
    #expect(report.sleepTalking == nil)
    #expect(report.rows.isEmpty)
    #expect(report.pages(firstPage: 5, perPage: 10) == [[]])
  }

  @Test func rowsSplitIntoPages() {
    let night = Night(
      start: start, end: start.addingTimeInterval(8 * 3600),
      events: (0..<12).map { event(Double($0), .snoring) })
    #expect(NightReport(night: night).pages(firstPage: 5, perPage: 4).map(\.count) == [5, 4, 3])
  }
}
