#if canImport(UIKit)
import SwiftUI
import Testing
@testable import SleepGuardContentKit

/// The tab title rows render in two themes. Set
/// `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct TabTitleRowTests {
  @Test func statisticsRendersInBothThemes() throws {
    try expectThemed(StatisticsTitleRow(onCalendar: {}), name: "title-row-statistics")
  }

  @Test func settingsRendersInBothThemes() throws {
    try expectThemed(SettingsTitleRow(), name: "title-row-settings")
  }

  private func expectThemed(_ row: some View, name: String) throws {
    let sleepGuard = try render(row.environment(\.theme, .sleepGuard))
    let alternate = try render(row.environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
    }
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.padding(20).frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
