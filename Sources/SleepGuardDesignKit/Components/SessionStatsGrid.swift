import SwiftUI

/// A night's four stats in a 2×2 grid: duration, snoring share, snore time, events.
public struct SessionStatsGrid: View {
  let duration: TimeInterval
  /// 0...1
  let snoringShare: Double
  let snoreTime: TimeInterval
  let eventCount: Int
  @Environment(\.theme) private var theme

  public init(duration: TimeInterval, snoringShare: Double, snoreTime: TimeInterval, eventCount: Int) {
    self.duration = duration
    self.snoringShare = snoringShare
    self.snoreTime = snoreTime
    self.eventCount = eventCount
  }

  public var body: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      StatCard(
        icon: "clock", title: Strings.recordingsPlayerStatDuration,
        value: Self.clock(duration), iconColor: theme.palette.accent)
      StatCard(
        icon: "percent", title: Strings.sessionSummaryStatSnoring,
        value: snoringShare.formatted(.percent.precision(.fractionLength(0))), iconColor: theme.palette.scoreAmber)
      StatCard(
        icon: "waveform", title: Strings.sessionSummaryStatSnoreTime,
        value: Self.clock(snoreTime), iconColor: theme.palette.scoreRed)
      StatCard(
        icon: "bolt.fill", title: Strings.recordingsDetailEventsLabel,
        value: "\(eventCount)", iconColor: theme.palette.scoreAmber)
    }
  }

  /// "8:24:13", or "4:05" under an hour.
  static func clock(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let (hours, minutes, seconds) = (total / 3600, total % 3600 / 60, total % 60)
    return hours > 0
      ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
      : String(format: "%d:%02d", minutes, seconds)
  }
}
