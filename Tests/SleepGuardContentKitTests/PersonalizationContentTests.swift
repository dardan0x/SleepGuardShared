#if canImport(UIKit)
import CoreGraphics
import SleepCore
import SwiftUI
import Testing
@testable import SleepGuardContentKit
import SleepGuardDesignKit
import SleepStrings

/// The briefing, the profile prompt and the report render; the briefing's
/// values read as SleepGuard's text; the PDF has one page per page of rows.
/// Set `TEST_RUNNER_DESIGN_KIT_RENDER_DIR` to keep the PNGs.
@MainActor
struct PersonalizationContentTests {
  @Test(arguments: PersonalizationContentGallery.Screen.allCases)
  func rendersInBothThemes(screen: PersonalizationContentGallery.Screen) throws {
    let sleepGuard = try render(PersonalizationContentGallery(screen: screen).environment(\.theme, .sleepGuard))
    #expect(sleepGuard.count > 1000)
    if screen != .reportFirstPage, screen != .reportLaterPage {
      // The report is printed: it doesn't follow the theme.
      let alternate = try render(PersonalizationContentGallery(screen: screen).environment(\.theme, .previewAlternate))
      #expect(sleepGuard != alternate)
    }
    if let directory = ProcessInfo.processInfo.environment["DESIGN_KIT_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("personalization-\(screen)-sleepguard.png"))
    }
  }

  @Test func briefingTextIsSleepGuards() {
    #expect(BriefingText.greeting(BriefingGreeting(part: .morning, name: "Alex")) == BriefingText.fill(Strings.briefingGreetingMorning, "Alex"))
    #expect(BriefingText.greeting(BriefingGreeting(part: .night, name: nil)) == Strings.briefingGreetingNightNoName)
    #expect(BriefingText.headline(.normal(duration: 8 * 3600 + 5 * 60, snoringMinutes: 30, score: 82, isLastNight: true))
      == BriefingText.fill(Strings.briefingHeadlineNormal, "8h 5m", "30", "82"))
    #expect(BriefingText.value(.minutesChange(12)) == "+12m")
    #expect(BriefingText.value(.pointsChange(-3)) == "-3")
    #expect(BriefingText.value(.duration(45 * 60)) == "45m")
    #expect(BriefingText.insight([.steady(average: 76), .goalShortfall(hours: 6, minutes: 30, shortMinutes: 90, targetHours: 8)])
      == BriefingText.fill(Strings.briefingInsightSteady, "76") + " "
      + BriefingText.fill(Strings.briefingInsightGoalShortfall, "6", "30", "90", "8"))
    #expect(BriefingText.insight([]) == nil)
    #expect(BriefingText.quote(.returningAfterGap(days: 5)) == Strings.briefingQuoteReturningAfterGap)
    #expect(Set(LifestyleChip.allCases.map(BriefingText.chip)).count == LifestyleChip.allCases.count)
  }

  @Test func theReportPDFHasAPagePerPageOfRows() throws {
    let report = NightReport(night: PersonalizationContentGallery.night)
    let capacity = NightReportPage.capacity(report)
    let expected = report.pages(firstPage: capacity.first, perPage: capacity.later).count
    let data = NightReportPDF.render(report, appName: "SleepGuard")
    let document = try #require(CGPDFDocument(CGDataProvider(data: data as CFData)!))
    #expect(document.numberOfPages == expected)
    #expect(expected >= 2)
    let url = try NightReportPDF.write(report, appName: "SleepGuard", to: FileManager.default.temporaryDirectory)
    #expect(url.pathExtension == "pdf")
    #expect(FileManager.default.fileExists(atPath: url.path))
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 612))
    renderer.scale = 1
    let image = try #require(renderer.uiImage)
    return try #require(image.pngData())
  }
}
#endif
