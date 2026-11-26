import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// One night below its title: score and stats, the timeline and the banners
/// that explain its gaps, the event filter, and the first events with "Show
/// all".
///
/// The screen owns `filter` (offer `EventFilter.options(for:)`) and does what
/// the actions ask. `onShare`, when given, adds Share to each row. `stages`
/// goes above the timeline (SleepGuard's sleep stages); `footer` below the
/// events (SleepGuard's short-events button).
public struct NightDetailContent<Stages: View, Footer: View>: View {
  let night: Night
  let summary: NightSummary
  let filters: [EventFilter]
  @Binding var filter: EventFilter
  let onPlay: (EventListRow) -> Void
  let onShowAll: ([EventListRow]) -> Void
  let onShare: ((EventListRow) -> Void)?
  let stages: Stages
  let footer: Footer
  @Environment(\.theme) private var theme

  /// Rows shown before "Show all".
  public static var visibleRows: Int {
    4
  }

  public init(
    night: Night,
    summary: NightSummary,
    filters: [EventFilter],
    filter: Binding<EventFilter>,
    onPlay: @escaping (EventListRow) -> Void,
    onShowAll: @escaping ([EventListRow]) -> Void,
    onShare: ((EventListRow) -> Void)? = nil,
    @ViewBuilder stages: () -> Stages,
    @ViewBuilder footer: () -> Footer)
  {
    self.night = night
    self.summary = summary
    self.filters = filters
    _filter = filter
    self.onPlay = onPlay
    self.onShowAll = onShowAll
    self.onShare = onShare
    self.stages = stages()
    self.footer = footer()
  }

  public var body: some View {
    let rows = EventListRow.rows(for: night, filter: filter)
    VStack(spacing: 24) {
      NightDetailHeader(night: night, summary: summary)

      VStack(alignment: .leading, spacing: 25) {
        stages
        NightTimeline(night: night)
      }

      if night.melodyGapsDuration > 0 {
        RecordingGapsBanner(totalGap: night.melodyGapsDuration)
      }
      if night.interruptionDuration > 0 {
        InterruptionGapsBanner(totalGap: night.interruptionDuration)
      }
      if night.endReason == .lowBattery {
        LowBatteryBanner()
      }

      if !filters.isEmpty {
        Picker(Strings.filterAll, selection: $filter) {
          ForEach(filters, id: \.self) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
      }

      VStack(alignment: .leading, spacing: 16) {
        Text(String(format: filter.listTitle, rows.count))
          .font(theme.typography.font(size: 12, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)

        VStack(spacing: 8) {
          ForEach(rows.prefix(Self.visibleRows)) { row in
            EventRow(
              start: row.start, duration: row.duration, category: row.category, intensity: row.intensity,
              onPlay: { onPlay(row) }, onShare: onShare.map { share in { share(row) } })
          }
        }

        if rows.count > Self.visibleRows {
          Button(String(format: Strings.recordingsDetailShowAllFormat, rows.count)) { onShowAll(rows) }
            .font(theme.typography.font(size: 15, weight: .medium))
            .foregroundStyle(theme.palette.accent)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
        }
      }

      footer
    }
    .padding(20)
  }
}

public extension NightDetailContent where Stages == EmptyView, Footer == EmptyView {
  init(
    night: Night,
    summary: NightSummary,
    filters: [EventFilter],
    filter: Binding<EventFilter>,
    onPlay: @escaping (EventListRow) -> Void,
    onShowAll: @escaping ([EventListRow]) -> Void,
    onShare: ((EventListRow) -> Void)? = nil)
  {
    self.init(
      night: night, summary: summary, filters: filters, filter: filter, onPlay: onPlay, onShowAll: onShowAll,
      onShare: onShare, stages: { EmptyView() }, footer: { EmptyView() })
  }
}

/// Score gauge, four stats, and a disturbances card when there are any.
public struct NightDetailHeader: View {
  let night: Night
  let summary: NightSummary
  @Environment(\.theme) private var theme

  public init(night: Night, summary: NightSummary) {
    self.night = night
    self.summary = summary
  }

  public var body: some View {
    let disturbances = night.events.filter { $0.category != .snoring }.count
    VStack(spacing: 12) {
      HStack(spacing: 16) {
        SleepScoreGauge(score: summary.score, size: 120)
        SessionStatsGrid(
          duration: night.duration, snoringShare: summary.snoringShare,
          snoreTime: summary.snoringDuration, eventCount: summary.eventCount)
      }
      if disturbances > 0 {
        StatCard(icon: "speaker.wave.2.fill", title: Strings.sessionDisturbances, value: "\(disturbances)", iconColor: theme.palette.noise)
      }
    }
  }
}

/// Every row as a card, three to a line: the events sheet's content.
public struct EventsGridContent: View {
  let rows: [EventListRow]
  let onPlay: (EventListRow) -> Void

  public init(rows: [EventListRow], onPlay: @escaping (EventListRow) -> Void) {
    self.rows = rows
    self.onPlay = onPlay
  }

  public var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
      ForEach(rows) { row in
        EventCard(start: row.start, duration: row.duration, category: row.category, intensity: row.intensity) { onPlay(row) }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 20)
  }
}

public extension EventFilter {
  var title: String {
    switch self {
    case .all: Strings.filterAll
    case .snoring: Strings.filterSnoring
    case .sleepTalking: Strings.filterSleepTalking
    case .noise: Strings.filterNoise
    }
  }

  /// A format with one count, e.g. "SNORING EVENTS · %lld".
  var listTitle: String {
    switch self {
    case .all: Strings.sessionRecordingEventsFormatAll
    case .snoring: Strings.sessionRecordingEventsFormatSnoring
    case .sleepTalking: Strings.sessionRecordingEventsFormatSleepTalking
    case .noise: Strings.sessionRecordingEventsFormatNoise
    }
  }
}
