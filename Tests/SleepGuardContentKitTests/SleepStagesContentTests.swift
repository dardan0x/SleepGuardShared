#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
@testable import SleepGuardDesignKit

/// The sleep-stage card and sheet render in two themes and the theme reaches
/// them; the texts and the hypnogram's hours. Set
/// `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct SleepStagesContentTests {
  @Test(arguments: SleepStagesContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: SleepStagesContentGallery.Screen) throws {
    let sleepGuard = try render(SleepStagesContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(SleepStagesContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("stages-\(screen)-sleepguard.png"))
    }
  }

  @Test func texts() throws {
    #expect(SleepStagesYourStages.label(.low) == Strings.sleepStagesInfoStageStatusLow)
    #expect(SleepStagesYourStages.recommendation(.deep) == Strings.sleepStagesInfoRecommendedDeep)
    #expect(SleepStage.deep.name == Strings.sleepStageDeepSleep)
    let breakdown = try #require(SleepStageBreakdown(segments: [
      SleepStageSegment(stage: .deep, startOffset: 0, duration: 25),
      SleepStageSegment(stage: .light, startOffset: 25, duration: 75),
    ]))
    #expect(SleepStageHypnogram.summary(breakdown)
      == "\(Strings.sleepStageDeep) 25%, \(Strings.sleepStageRem) 0%, \(Strings.sleepStageLight) 75%, \(Strings.sleepStageAwake) 0%")
  }

  @Test func hourMarkersFallOnFullHours() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
    let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 23, minute: 30)))
    let markers = SleepStageHypnogram.hourMarkers(start: start, duration: 2 * 3600, calendar: calendar)
    #expect(markers.map(\.label) == ["00", "01"])
    #expect(markers.map(\.ratio) == [0.25, 0.75])
  }

  @Test func barScaleLeavesRoomPastTheLarger() {
    #expect(SleepStagesScoreImpact.scale(value: 10, target: 15, isMinimum: true) == 18)
    #expect(SleepStagesScoreImpact.scale(value: 10, target: 8, isMinimum: false) == 15)
    #expect(SleepStagesScoreImpact.scale(value: 0, target: 0, isMinimum: true) == 1)
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
