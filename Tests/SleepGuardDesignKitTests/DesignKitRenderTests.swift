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
