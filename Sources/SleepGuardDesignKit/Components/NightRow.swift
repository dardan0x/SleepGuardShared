import SwiftUI

/// One night in a list of nights: time span, event count, score. Taps open it.
public struct NightRow: View {
  let start: Date
  let end: Date
  let eventCount: Int
  let score: Int
  let onOpen: () -> Void
  @Environment(\.theme) private var theme

  public init(start: Date, end: Date, eventCount: Int, score: Int, onOpen: @escaping () -> Void) {
    self.start = start
    self.end = end
    self.eventCount = eventCount
    self.score = score
    self.onOpen = onOpen
  }

  public var body: some View {
    Button(action: onOpen) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          // Times only: a night crosses midnight, and the list already shows the day.
          Text("\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
            .font(theme.typography.font(size: 14, weight: .medium))
            .foregroundStyle(theme.palette.textPrimary)
          Text(String(format: Strings.recordingsDetailEventsCountFormat, eventCount))
            .font(theme.typography.font(size: 12))
            .foregroundStyle(theme.palette.textSecondary)
        }
        Spacer()
        ScoreBadge(score: score, size: 32)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
