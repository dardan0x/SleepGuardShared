import SleepCore
import SwiftUI

/// The nights list: a section per month (`NightMonth.months(from:)`), a card
/// per day. Tapping a day with one night opens it; a day with several expands.
/// Swiping a day, or a long press on it, asks to delete it: the screen
/// confirms and deletes.
public struct NightsListContent: View {
  let months: [NightMonth]
  let onOpen: (NightSummary) -> Void
  let onDelete: (NightDay) -> Void
  @State private var expanded: Set<NightDay.ID> = []

  public init(months: [NightMonth], onOpen: @escaping (NightSummary) -> Void, onDelete: @escaping (NightDay) -> Void) {
    self.months = months
    self.onOpen = onOpen
    self.onDelete = onDelete
  }

  public var body: some View {
    List {
      ForEach(months) { month in
        Section {
          ForEach(month.days) { day in
            NightDayCard(
              day: day, isExpanded: expanded.contains(day.id), onOpen: onOpen, onToggle: { toggle(day) },
              onDeleteRequest: { onDelete(day) })
              .padding(.vertical, 8)
              .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                  onDelete(day)
                } label: {
                  Label(Strings.actionDelete, systemImage: "trash")
                }
              }
              .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
          }
        } header: {
          NightMonthHeader(month: month.month)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    }
    .padding(.bottom, 10)
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private func toggle(_ day: NightDay) {
    withAnimation(.easeInOut(duration: 0.2)) {
      if expanded.remove(day.id) == nil { expanded.insert(day.id) }
    }
  }
}

/// A month's section header ("NOVEMBER 2026").
public struct NightMonthHeader: View {
  let month: Date
  @Environment(\.theme) private var theme

  public init(month: Date) {
    self.month = month
  }

  public var body: some View {
    Text(month.formatted(.dateTime.month(.wide).year()))
      .font(theme.typography.font(size: 13, weight: .semibold))
      .foregroundStyle(theme.palette.textTertiary)
      .textCase(.uppercase)
  }
}

/// One day: date, recordings, length, events, average score. Tapping a day
/// with one night opens it; with several, `onToggle` asks to expand or
/// collapse it (the list owns `isExpanded`). A long press asks to delete it.
public struct NightDayCard: View {
  let day: NightDay
  let isExpanded: Bool
  let onOpen: (NightSummary) -> Void
  let onToggle: () -> Void
  let onDeleteRequest: () -> Void
  @Environment(\.theme) private var theme

  public init(
    day: NightDay, isExpanded: Bool, onOpen: @escaping (NightSummary) -> Void, onToggle: @escaping () -> Void,
    onDeleteRequest: @escaping () -> Void)
  {
    self.day = day
    self.isExpanded = isExpanded
    self.onOpen = onOpen
    self.onToggle = onToggle
    self.onDeleteRequest = onDeleteRequest
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text(Self.title(day.date))
            .font(theme.typography.font(size: 16, weight: .semibold))
            .foregroundStyle(theme.palette.textPrimary)
          NightDayDetails(day: day)
        }
        Spacer()
        ScoreBadge(score: day.averageScore, size: 40)
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .accessibilityHidden(true)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .contentShape(Rectangle())
      .onTapGesture(perform: tap)
      .onLongPressGesture(minimumDuration: 0.5, perform: onDeleteRequest)
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isButton)
      .accessibilityAction(named: Strings.actionDelete, onDeleteRequest)

      if isExpanded {
        VStack(spacing: 8) {
          Divider()
            .background(theme.palette.textTertiary.opacity(0.2))
            .padding(.horizontal, 16)
          ForEach(day.nights) { night in
            NightRow(start: night.start, end: night.end, eventCount: night.eventCount, score: night.score) { onOpen(night) }
          }
        }
        .padding(.bottom, 12)
      }
    }
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }

  /// The medium date for the locale ("Nov 16, 2026", "16 Nov 2026").
  static func title(_ date: Date) -> String {
    DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
  }

  private func tap() {
    if day.nights.count == 1 {
      onOpen(day.nights[0])
    } else {
      onToggle()
    }
  }
}

/// "2 recordings · 7h 12 mins • 5 events".
struct NightDayDetails: View {
  let day: NightDay
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 6) {
      if day.nights.count > 1 {
        Text(String(format: Strings.sessionsDetailSessionsCountFormat, day.nights.count))
          .font(theme.typography.font(size: 11, weight: .semibold))
          .foregroundStyle(theme.palette.accent)
          .lineLimit(1)
          .fixedSize()
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(theme.palette.accent.opacity(0.15), in: .capsule)
      }
      Text(DurationText.hoursAndMinutes(day.duration))
        .fixedSize()
      Text("•")
        .font(.system(size: 10))
        .accessibilityHidden(true)
      Text(String(format: Strings.recordingsDetailEventsCountFormat, day.eventCount))
        .fixedSize()
    }
    .font(theme.typography.font(size: 13))
    .foregroundStyle(theme.palette.textSecondary)
  }
}

/// No nights recorded yet.
public struct NightsListEmptyContent: View {
  @Environment(\.theme) private var theme

  public init() {}

  public var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 48))
        .foregroundStyle(theme.palette.textTertiary)
        .accessibilityHidden(true)
      Text(Strings.recordingsEmptyTitle)
        .font(theme.typography.font(size: 20, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)
      Text(Strings.recordingsEmptyMessage)
        .font(theme.typography.font(size: 15))
        .foregroundStyle(theme.palette.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Placeholder cards while the first list loads.
public struct NightsListLoadingContent: View {
  public init() {}

  public var body: some View {
    let placeholder = NightDay(
      date: .now,
      nights: [NightSummary(id: UUID(), start: .now, end: .now.addingTimeInterval(8 * 3600), score: 80, snoringDuration: 0, eventCount: 3)])
    VStack(spacing: 16) {
      ForEach(0..<4, id: \.self) { _ in
        NightDayCard(day: placeholder, isExpanded: false, onOpen: { _ in }, onToggle: {}, onDeleteRequest: {})
      }
      Spacer()
    }
    .padding(16)
    .redacted(reason: .placeholder)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
