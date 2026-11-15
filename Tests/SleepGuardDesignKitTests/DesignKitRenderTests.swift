#if canImport(UIKit)
// Renders through UIKit, so these tests run on the iOS Simulator lane only
// (scripts/run-tests.sh); `swift test` on macOS compiles this file out.
import SwiftUI
import Testing
@testable import SleepGuardDesignKit

/// Every component renders in two themes, and the theme reaches them: the two
/// renders differ. Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs
/// for a visual check.
@MainActor
struct DesignKitRenderTests {
  @Test(arguments: [("sleepguard", Theme.sleepGuard), ("alternate", Theme.previewAlternate)])
  func galleryRenders(name: String, theme: Theme) throws {
    let png = try render(DesignKitGallery().environment(\.theme, theme))
    #expect(png.count > 1000)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("gallery-\(name).png"))
    }
  }

  @Test func themeChangesTheRender() throws {
    let first = try render(DesignKitGallery().environment(\.theme, .sleepGuard))
    let second = try render(DesignKitGallery().environment(\.theme, .previewAlternate))
    #expect(first != second)
  }

  @Test(arguments: [("sleepguard", Theme.sleepGuard), ("alternate", Theme.previewAlternate)])
  func detailComponentsRender(name: String, theme: Theme) throws {
    let png = try render(DetailGallery().environment(\.theme, theme))
    #expect(png.count > 1000)
    #expect(try png != render(DetailGallery().environment(\.theme, name == "sleepguard" ? .previewAlternate : .sleepGuard)))
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("detail-\(name).png"))
    }
  }

  @Test(arguments: [("sleepguard", Theme.sleepGuard), ("alternate", Theme.previewAlternate)])
  func statisticsComponentsRender(name: String, theme: Theme) throws {
    let png = try render(StatisticsGallery().environment(\.theme, theme))
    #expect(png.count > 1000)
    #expect(try png != render(StatisticsGallery().environment(\.theme, name == "sleepguard" ? .previewAlternate : .sleepGuard)))
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("statistics-\(name).png"))
    }
  }

  @Test func eventColours() {
    let palette = Theme.sleepGuard.palette
    #expect(palette.eventColor(.snoring, intensity: .quiet) == palette.snoreQuiet)
    #expect(palette.eventColor(.snoring, intensity: .epic) == palette.snoreEpic)
    #expect(palette.eventColor(.sleepTalking, intensity: .epic) == palette.sleepTalking)
    #expect(palette.eventColor(.coughing, intensity: .loud) == palette.noise)
    #expect(palette.eventColor(.other, intensity: .quiet) == palette.noise)
  }

  @Test func durationFormats() {
    #expect(SessionStatsGrid.clock(30253) == "8:24:13")
    #expect(SessionStatsGrid.clock(245) == "4:05")
    #expect(DurationText.over(40) == "\(Strings.commonOver) 40 \(Strings.settingsUnitSecondsShort)")
    #expect(DurationText.over(3900) == "\(Strings.commonOver) 1 \(Strings.timeHourSingular) 5 \(Strings.timeMinutePlural)")
    #expect(DurationText.hoursAndMinutes(60) == "1 \(Strings.timeMinuteSingular)")
  }

  @Test func scoreBands() {
    let palette = Theme.sleepGuard.palette
    #expect(Theme.sleepGuard.scoreColor(100) == palette.scoreGreen)
    #expect(Theme.sleepGuard.scoreColor(80) == palette.scoreGreen)
    #expect(Theme.sleepGuard.scoreColor(79) == palette.scoreAmber)
    #expect(Theme.sleepGuard.scoreColor(50) == palette.scoreAmber)
    #expect(Theme.sleepGuard.scoreColor(49) == palette.scoreRed)
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
