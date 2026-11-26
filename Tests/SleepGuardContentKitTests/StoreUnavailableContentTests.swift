#if canImport(UIKit)
import SwiftUI
import Testing
@testable import SleepGuardContentKit
import SleepGuardDesignKit

/// The store-unavailable screen renders in two themes, and the update button
/// is drawn only when there is an action for it. Set
/// `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNG.
@MainActor
struct StoreUnavailableContentTests {
  @Test func rendersInBothThemes() throws {
    let sleepGuard = try render(StoreUnavailableContentGallery().environment(\.theme, .sleepGuard))
    let alternate = try render(StoreUnavailableContentGallery().environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("store-unavailable-sleepguard.png"))
    }
  }

  @Test func withoutAnActionTheUpdateButtonIsLeftOut() throws {
    let with = try render(StoreUnavailableContentGallery(showsUpdate: true).environment(\.theme, .sleepGuard))
    let without = try render(StoreUnavailableContentGallery(showsUpdate: false).environment(\.theme, .sleepGuard))
    #expect(with != without)
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
