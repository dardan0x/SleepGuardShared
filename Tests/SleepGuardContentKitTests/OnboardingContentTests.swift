#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
import SleepGuardDesignKit

/// Every onboarding page renders in two themes. Set
/// `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct OnboardingContentTests {
  @Test(arguments: OnboardingContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: OnboardingContentGallery.Screen) throws {
    let sleepGuard = try render(OnboardingContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(OnboardingContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("onboarding-\(screen)-sleepguard.png"))
    }
  }

  @Test func theContentBuildsForEitherPageList() {
    for hasHealth in [true, false] {
      _ = OnboardingContent(
        pages: OnboardingPages(hasHealth: hasHealth), current: .constant(.welcome), microphone: .notAsked,
        health: .notAsked, onRequestMicrophone: {}, onRequestHealth: {}, onStartRecording: {}, onBrowse: {}).body
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
