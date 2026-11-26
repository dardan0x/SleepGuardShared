#if canImport(UIKit)
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
@testable import SleepGuardDesignKit
import SleepStrings

/// The interrupter's pieces render in two themes; names and labels come from
/// the catalog. Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct SnoreInterrupterContentTests {
  @Test(arguments: SnoreInterrupterContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: SnoreInterrupterContentGallery.Screen) throws {
    let sleepGuard = try render(SnoreInterrupterContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    let alternate = try render(SnoreInterrupterContentGallery(screen: screen).environment(\.theme, .previewAlternate))
    #expect(sleepGuard.count > 1000)
    #expect(sleepGuard != alternate)
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("interrupter-\(screen)-sleepguard.png"))
    }
  }

  @Test func namesAndLabels() {
    #expect(Melody.resolve(id: 6, custom: []).name == Strings.melodyAttentionChime)
    #expect(Set(Melody.builtIn.map(\.name)).count == Melody.builtIn.count)
    #expect(!Melody.builtIn.map(\.name).contains(Strings.snoreInterrupterDefaultMelodyName))
    #expect(Melody(id: 100, filename: "custom_100.m4a", customName: "Snore stopper").name == "Snore stopper")
    #expect(Melody.customName(number: 3) == String(format: Strings.melodyCustomNameFormat, 3))
    #expect(SnoreInterrupterMode.never.label == Strings.snoreInterrupterOffValueFormat)
    #expect(SnoreInterrupterMode.sixtySeconds.label == Strings.snoreInterrupterSixtySecondsValueFormat)
  }

  @Test func recordingTime() {
    #expect(RecordMelodyContent.timeText(0) == "0.0")
    #expect(RecordMelodyContent.timeText(4.76) == "4.7")
    #expect(RecordMelodyContent.timeText(10) == "10.0")
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390))
    renderer.scale = 2
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
