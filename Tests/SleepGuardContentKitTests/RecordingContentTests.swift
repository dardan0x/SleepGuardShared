#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
import SleepGuardDesignKit

/// The recording screens' content renders in two themes and the theme
/// reaches it. Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct RecordingContentTests {
  @Test(arguments: RecordingContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: RecordingContentGallery.Screen) throws {
    let sleepGuard = try render(RecordingContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(RecordingContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("recording-\(screen)-sleepguard.png"))
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
