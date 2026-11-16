#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit

/// The nights list content renders in two themes and the theme reaches it.
/// Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct NightsContentTests {
  /// Not `.list`: `ImageRenderer` can't draw a `List` (UIKit-backed); every
  /// view inside it is drawn by `.expandedDay`. The list is checked in the apps.
  @Test(arguments: [NightsContentGallery.Screen.expandedDay, .empty, .loading])
  func rendersInBothThemes(screen: NightsContentGallery.Screen) throws {
    let sleepGuard = try render(NightsContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(NightsContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("nights-\(screen)-sleepguard.png"))
    }
  }

  /// SleepGuard's `DateFormatters.mediumDate`.
  @Test func dayTitleIsTheMediumDate() {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    let date = Date(timeIntervalSinceReferenceDate: 815_000_000)
    #expect(NightDayCard.title(date) == formatter.string(from: date))
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
