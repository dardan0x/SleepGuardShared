import SleepCore
import SwiftUI

/// One US Letter page of a night's report: the first page has the summary,
/// later pages continue the events table. Printed colours, not the app's
/// theme: a report reads the same whichever app or theme made it.
struct NightReportPage: View {
  let report: NightReport
  let appName: String
  /// 0 is the first page.
  let index: Int
  let rows: [NightReport.Row]
  /// An earlier page already started the events table.
  var continued = false

  static let size = CGSize(width: 612, height: 792)
  static let margin: CGFloat = 40
  static let rowHeight: CGFloat = 44

  /// Rows that fit under the first page's summary, and on a later page.
  /// Conservative: a row that doesn't fit would be cut off the page.
  static func capacity(_ report: NightReport) -> (first: Int, later: Int) {
    // Header, score card, two rows of stats, the events title and columns, the footer.
    var used: CGFloat = 140 + 32 + 140 + 32 + 196 + 32 + 64 + 56
    if report.stages != nil { used += 140 + 32 }
    if report.sleepTalking != nil { used += 80 + 32 }
    let first = Int(max(0, size.height - used) / rowHeight)
    let later = Int((size.height - margin - 64 - 56) / rowHeight)
    return (first, later)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if index == 0 {
        ReportHeader(title: BriefingText.fill(Strings.reportTitleFormat, appName), date: report.start)
        VStack(alignment: .leading, spacing: 32) {
          ReportScoreCard(report: report)
          ReportStatsGrid(report: report)
          if let stages = report.stages { ReportStages(stats: stages) }
          if let talking = report.sleepTalking { ReportSleepTalking(talking: talking) }
          if !rows.isEmpty { ReportEvents(rows: rows) }
        }
        .padding(.horizontal, Self.margin)
        .padding(.top, 32)
      } else {
        ReportEvents(rows: rows, continued: continued)
          .padding(.horizontal, Self.margin)
          .padding(.top, Self.margin)
      }
      Spacer(minLength: 0)
      Text(BriefingText.fill(Strings.reportFooterFormat, appName))
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(ReportPalette.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.bottom, Self.margin - 10)
    }
    .frame(width: Self.size.width, height: Self.size.height, alignment: .top)
    .background(Color.white)
    .environment(\.colorScheme, .light)
  }
}

/// The report's printed colours (SleepGuard's report).
enum ReportPalette {
  static let gradient = [
    Color(red: 0.50, green: 0.85, blue: 0.95), Color(red: 0.10, green: 0.45, blue: 0.75),
    Color(red: 0.05, green: 0.15, blue: 0.40),
  ]
  static let card = Color(red: 0.94, green: 0.97, blue: 1.0)
  static let row = Color(red: 0.96, green: 0.98, blue: 1.0)
  static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
  static let textSecondary = Color(red: 0.45, green: 0.50, blue: 0.58)
  static let divider = Color(red: 0.85, green: 0.85, blue: 0.87)

  static func score(_ rating: NightReport.Rating) -> Color {
    switch rating {
    case .excellent: Color(red: 0.188, green: 0.82, blue: 0.345)
    case .fair: Color(red: 1, green: 0.624, blue: 0.039)
    case .poor: Color(red: 1, green: 0.271, blue: 0.227)
    }
  }

  static func intensity(_ intensity: SnoreIntensity) -> Color {
    switch intensity {
    case .quiet: Color(red: 0.55, green: 0.55, blue: 0.55)
    case .light: Color(red: 1, green: 0.624, blue: 0.039)
    case .loud: Color(red: 1, green: 0.271, blue: 0.227)
    case .epic: Color(red: 1, green: 0.176, blue: 0.333)
    }
  }

  static func stage(_ stage: SleepStage) -> Color {
    switch stage {
    case .deep: Color(red: 0.369, green: 0.361, blue: 0.902)
    case .light: Color(red: 0.039, green: 0.518, blue: 1.0)
    case .rem: Color(red: 0.392, green: 0.824, blue: 1.0)
    case .awake: Color(red: 1.0, green: 0.839, blue: 0.039)
    }
  }
}

enum ReportText {
  static func rating(_ rating: NightReport.Rating) -> String {
    switch rating {
    case .excellent: Strings.reportRatingExcellent
    case .fair: Strings.reportRatingFair
    case .poor: Strings.reportRatingPoor
    }
  }

  static func kind(_ kind: NightReport.Row.Kind) -> String {
    switch kind {
    case .snoring: Strings.filterSnoring
    case .sleepTalking: Strings.filterSleepTalking
    case .noise: Strings.filterNoise
    }
  }

  static func intensity(_ intensity: SnoreIntensity) -> String {
    switch intensity {
    case .quiet: Strings.quietIntensityLabel
    case .light: Strings.lightIntensityLabelEventPlayerView
    case .loud: Strings.loudIntensityLabelEventPlayerView
    case .epic: Strings.epicIntensityLabelEventPlayerView
    }
  }

  /// "1:02:03", or "2:03" under an hour (SleepGuard's report).
  static func duration(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    return hours > 0
      ? String(format: "%d:%02d:%02d", hours, minutes, total % 60)
      : String(format: "%d:%02d", minutes, total % 60)
  }

  /// "42%".
  static func percent(_ value: Double) -> String {
    String(format: "%.0f%%", value)
  }
}
