#if canImport(UIKit)
import SwiftUI
import Testing
@testable import SleepGuardContentKit

/// The Learn tab without a page renders in two themes; with one it builds;
/// the external-link script looks for the marked links and posts to its
/// handler. Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNG.
@MainActor
struct LearnContentTests {
  @Test func theEmptyStateRendersInBothThemes() throws {
    let sleepGuard = try render(LearnContentGallery().environment(\.theme, .sleepGuard))
    let alternate = try render(LearnContentGallery().environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("learn-empty-sleepguard.png"))
    }
  }

  @Test func withAPageItBuilds() throws {
    _ = LearnContent(url: try #require(URL(string: "https://example.com/learn"))).body
  }

  @Test func theScriptCatchesMarkedLinksForItsHandler() {
    #expect(LearnWebView.clickInterceptor.contains("data-open-external"))
    #expect(LearnWebView.clickInterceptor.contains("handlers.\(LearnWebView.messageName).postMessage(target.href)"))
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
