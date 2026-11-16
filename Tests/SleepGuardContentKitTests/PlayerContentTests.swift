#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit

/// The player content renders in two themes and the theme reaches it; the
/// 15-second skip lands where both apps' players put it.
@MainActor
struct PlayerContentTests {
  @Test(arguments: PlayerContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: PlayerContentGallery.Screen) throws {
    let sleepGuard = try render(PlayerContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(PlayerContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("player-\(screen)-sleepguard.png"))
    }
  }

  @Test func skipping() {
    #expect(PlayerCard.position(skipping: 15, from: 30, of: 90) == 0.5)
    #expect(PlayerCard.position(skipping: -15, from: 10, of: 100) == 0)
    #expect(PlayerCard.position(skipping: 15, from: 0, of: 0) == nil)
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
