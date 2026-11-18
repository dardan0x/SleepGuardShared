import SleepCore
import SwiftUI

/// The nights list content with sample nights, for previews and render tests.
/// Internal: sample data only.
struct NightsContentGallery: View {
  enum Screen: CaseIterable {
    case list
    case expandedDay
    case empty
    case loading
  }

  let screen: Screen
  private static let now = Date(timeIntervalSinceReferenceDate: 815_000_000)

  /// Two months of nights; one day with two recordings.
  static let nights: [NightSummary] = {
    let day = 86400.0
    let starts = [1.0, 2, 3, 5, 9, 33, 36].map { now.addingTimeInterval(-$0 * day) }
    var nights = starts.enumerated().map { index, start in
      NightSummary(
        id: UUID(), start: start, end: start.addingTimeInterval(7 * 3600 + Double(index) * 900),
        score: [82, 64, 91, 45, 77, 58, 88][index], snoringDuration: 0, eventCount: index % 4)
    }
    let nap = now.addingTimeInterval(-day - 3 * 3600) // same day as the latest night, earlier
    nights.append(NightSummary(id: UUID(), start: nap, end: nap.addingTimeInterval(1800), score: 70, snoringDuration: 0, eventCount: 1))
    return nights
  }()

  var body: some View {
    Group {
      switch screen {
      case .list:
        NightsListContent(months: NightMonth.months(from: Self.nights), onOpen: { _ in }, onDelete: { _ in })
          .frame(height: 760)
      case .expandedDay:
        if let day = NightMonth.months(from: Self.nights).first?.days.first(where: { $0.nights.count > 1 }) {
          VStack(spacing: 8) {
            NightDayCard(day: day, isExpanded: true, onOpen: { _ in }, onToggle: {}, onDeleteRequest: {})
          }
          .padding(16)
        }
      case .empty:
        NightsListEmptyContent().frame(height: 500)
      case .loading:
        NightsListLoadingContent().frame(height: 600)
      }
    }
    .background(NightsContentBackground())
  }
}

private struct NightsContentBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Nights list") {
  NightsContentGallery(screen: .list)
}

#Preview("Day with two recordings") {
  NightsContentGallery(screen: .expandedDay)
    .environment(\.theme, .previewAlternate)
}
