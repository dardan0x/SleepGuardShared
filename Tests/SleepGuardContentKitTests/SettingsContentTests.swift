#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
import SleepGuardDesignKit

/// Settings, the profile editor, the start delay and the countdown render in two themes and the theme
/// reaches it. Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct SettingsContentTests {
  @Test(arguments: SettingsContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: SettingsContentGallery.Screen) throws {
    let sleepGuard = try render(SettingsContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(SettingsContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("settings-\(screen)-sleepguard.png"))
    }
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
