import SleepCore
import SwiftUI
import SleepGuardDesignKit

/// The briefing sheet (each kind of headline and the survey), the profile
/// prompt card and the report's pages with sample nights, for previews and
/// render tests. Internal: sample data only.
struct PersonalizationContentGallery: View {
  enum Screen: CaseIterable {
    case briefingRecap, briefingWeekly, briefingWelcome, profilePrompt, reportFirstPage, reportLaterPage
  }

  let screen: Screen

  static let now = Date(timeIntervalSinceReferenceDate: 815_000_000 + 8 * 3600)

  /// Recent nights ending this morning, oldest last, with varied scores.
  static func nights(count: Int) -> [NightSummary] {
    let scores = [84, 71, 76, 68, 79]
    let snoringMinutes: [Double] = [22, 35, 12, 40, 18]
    return (0..<count).map { index in
      let start: Date = now.addingTimeInterval(-Double(index + 1) * 86400 - 9 * 3600)
      let hours: [Double] = [7.5, 6.8, 7.2, 6.4, 7.0]
      let end: Date = start.addingTimeInterval(hours[index % 5] * 3600)
      return NightSummary(
        id: UUID(), start: start, end: end, score: scores[index % 5],
        snoringDuration: snoringMinutes[index % 5] * 60, eventCount: 12)
    }
  }

  static var night: Night {
    let start: Date = now.addingTimeInterval(-9 * 3600)
    let intensities: [SnoreIntensity] = [.quiet, .light, .loud, .epic]
    let events: [NightEvent] = (0..<24).map { (index: Int) -> NightEvent in
      let category: SoundCategory = index % 7 == 3 ? .sleepTalking : .snoring
      let offset = Double(index) * 900 + 600
      return NightEvent(
        start: start.addingTimeInterval(offset), duration: Double(20 + index * 3), category: category,
        intensity: intensities[index % 4])
    }
    return Night(start: start, end: start.addingTimeInterval(7.5 * 3600), events: events)
  }

  static func briefing(_ nights: [NightSummary]) -> Briefing {
    var profile = SleepProfile()
    profile.firstName = "Alex"
    profile.targetSleepHours = 8
    return BriefingEngine.make(nights: nights, profile: profile, logs: [], now: now)
  }

  var body: some View {
    switch screen {
    case .briefingRecap:
      BriefingStack(briefing: Self.briefing(Array(Self.nights(count: 5).prefix(1))), onChip: { _ in }, onClose: {})
        .background(GalleryBackground())
    case .briefingWeekly:
      BriefingStack(briefing: Self.briefing(Self.nights(count: 5)), onChip: { _ in }, onClose: {})
        .background(GalleryBackground())
    case .briefingWelcome:
      BriefingStack(briefing: Self.briefing([]), onChip: { _ in }, onClose: {})
        .background(GalleryBackground())
    case .profilePrompt:
      ProfilePromptCard(onOpen: {}, onDismiss: {}).padding(16).background(GalleryBackground())
    case .reportFirstPage:
      let report = NightReport(night: Self.night)
      NightReportPage(report: report, appName: "SleepGuard", index: 0, rows: Array(report.rows.prefix(NightReportPage.capacity(report).first)))
    case .reportLaterPage:
      let report = NightReport(night: Self.night)
      NightReportPage(report: report, appName: "SleepGuard", index: 1, rows: Array(report.rows.suffix(8)), continued: true)
    }
  }
}

private struct GalleryBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Briefing") {
  BriefingContent(briefing: PersonalizationContentGallery.briefing(PersonalizationContentGallery.nights(count: 5)), onChip: { _ in }, onClose: {})
}

#Preview("Report") {
  ScrollView {
    PersonalizationContentGallery(screen: .reportFirstPage)
  }
}
