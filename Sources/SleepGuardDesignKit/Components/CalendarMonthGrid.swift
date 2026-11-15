import SleepCore
import SwiftUI

/// Month title with previous / next buttons, and "Today" when given.
public struct MonthHeader: View {
  let title: String
  let onPrevious: () -> Void
  let onNext: () -> Void
  let onToday: (() -> Void)?
  @Environment(\.theme) private var theme

  public init(title: String, onPrevious: @escaping () -> Void, onNext: @escaping () -> Void, onToday: (() -> Void)? = nil) {
    self.title = title
    self.onPrevious = onPrevious
    self.onNext = onNext
    self.onToday = onToday
  }

  public var body: some View {
    HStack {
      Text(title)
        .font(theme.typography.font(size: 20, weight: .bold))
        .foregroundStyle(theme.palette.textPrimary)
      Spacer()
      HStack(spacing: 16) {
        if let onToday {
          Button(Strings.statsMiniChartToday, action: onToday)
            .font(theme.typography.font(size: 15, weight: .medium))
            .foregroundStyle(theme.palette.accent)
        }
        Button(action: onPrevious) {
          Label(Strings.a11yPreviousMonth, systemImage: "chevron.left").labelStyle(.iconOnly)
        }
        Button(action: onNext) {
          Label(Strings.a11yNextMonth, systemImage: "chevron.right").labelStyle(.iconOnly)
        }
      }
      .font(.system(size: 15, weight: .semibold))
      .foregroundStyle(theme.palette.textSecondary)
    }
  }
}

/// Weekday initials over a 6-week grid of days. A day with a night shows a dot
/// in its loudest intensity's colour; the selected day is filled with the accent.
public struct CalendarMonthGrid: View {
  public struct Day: Sendable, Equatable {
    public let date: Date
    public let isInMonth: Bool
    public let isSelected: Bool
    /// `nil`: no night, or a night without events (no dot).
    public let loudest: SnoreIntensity?

    public init(date: Date, isInMonth: Bool, isSelected: Bool, loudest: SnoreIntensity?) {
      self.date = date
      self.isInMonth = isInMonth
      self.isSelected = isSelected
      self.loudest = loudest
    }
  }

  let days: [Day]
  let onSelect: (Date) -> Void
  @Environment(\.theme) private var theme

  public init(days: [Day], onSelect: @escaping (Date) -> Void) {
    self.days = days
    self.onSelect = onSelect
  }

  public var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 0) {
        ForEach(Array(Self.weekdayInitials.enumerated()), id: \.offset) { _, initial in
          Text(initial)
            .font(theme.typography.font(size: 12, weight: .medium))
            .foregroundStyle(theme.palette.textTertiary)
            .frame(maxWidth: .infinity)
        }
      }
      ForEach(0..<(days.count / 7), id: \.self) { row in
        HStack(spacing: 8) {
          ForEach(days[row * 7..<row * 7 + 7], id: \.date) { cell($0) }
        }
      }
    }
  }

  /// One-letter weekday names starting on the calendar's first weekday.
  static var weekdayInitials: [String] {
    let calendar = Calendar.current
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    let first = calendar.firstWeekday - 1
    return Array(symbols[first...] + symbols[..<first])
  }

  private func cell(_ day: Day) -> some View {
    let dot = day.loudest.map { theme.palette.eventColor(.snoring, intensity: $0) }
    let background: Color = day.isSelected ? theme.palette.accent : (dot == nil ? .clear : theme.palette.bgElevated)
    let number: Color = day.isSelected
      ? .white
      : (day.isInMonth ? theme.palette.textPrimary : theme.palette.textTertiary.opacity(0.5))
    return Button {
      withAnimation(.easeInOut(duration: 0.15)) { onSelect(day.date) }
    } label: {
      VStack(spacing: 4) {
        Text(day.date.formatted(.dateTime.day()))
          .font(theme.typography.font(size: 15, weight: .medium))
          .foregroundStyle(number)
          .frame(width: 36, height: 36)
        Circle()
          .fill(day.isSelected ? Color.white : (dot ?? .clear))
          .frame(width: 5, height: 5)
          .opacity(dot == nil ? 0 : 1)
      }
      .frame(maxWidth: .infinity, minHeight: 52)
      .background(background, in: .rect(cornerRadius: theme.radii.small))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(day.isSelected ? .isSelected : [])
  }
}
