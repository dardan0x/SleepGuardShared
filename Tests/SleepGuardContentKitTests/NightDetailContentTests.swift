#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
import SleepGuardDesignKit
import SleepStrings

/// The night detail and events grid render in two themes and the theme
/// reaches them. Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct NightDetailContentTests {
  @Test(arguments: NightDetailContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: NightDetailContentGallery.Screen) throws {
    let sleepGuard = try render(NightDetailContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(NightDetailContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("detail-\(screen)-sleepguard.png"))
    }
  }

  @Test func filterTexts() {
    #expect(EventFilter.snoring.title == Strings.filterSnoring)
    #expect(EventFilter.noise.listTitle == Strings.sessionRecordingEventsFormatNoise)
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
