import SleepCore
import SwiftUI
import SleepStrings

// The recording screens' pieces, from SleepGuard's SleepSession views: the
// prestart header and tips, the bedside clock's parts, and the summary's
// header and actions. Values in, drawing out; the screens stay in each app.

// MARK: - Prestart

/// Moon tile, title and body copy at the top of the prestart screen.
public struct PrestartHeader: View {
  let compact: Bool
  @Environment(\.theme) private var theme

  /// `compact` for short screens (SleepGuard: height ≤ 874 pt).
  public init(compact: Bool = false) {
    self.compact = compact
  }

  public var body: some View {
    VStack(spacing: 8) {
      RoundedRectangle(cornerRadius: compact ? 20 : 24)
        .fill(theme.palette.bgCard)
        .frame(width: compact ? 80 : 100, height: compact ? 80 : 100)
        .overlay(
          Image(systemName: "moon.fill")
            .font(.system(size: compact ? 36 : 44))
            .foregroundStyle(theme.palette.accent))
        .accessibilityHidden(true)

      Text(Strings.statsEmptyTitle)
        .font(theme.typography.font(size: compact ? 22 : 28, weight: .bold))
        .foregroundStyle(theme.palette.textPrimary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      Text(Strings.sessionPrestartBody)
        .font(theme.typography.font(size: compact ? 14 : 16))
        .foregroundStyle(theme.palette.textSecondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

/// The glowing tips card: keep the phone close, stay plugged in.
public struct PrestartTipsCard: View {
  @Environment(\.theme) private var theme

  public init() {}

  public var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: theme.radii.card)
        .fill(theme.palette.scoreRed.opacity(0.12))
        .blur(radius: 12)
        .offset(y: 4)
        .padding(.horizontal, -4)
      RoundedRectangle(cornerRadius: theme.radii.card)
        .fill(LinearGradient(
          colors: [theme.palette.scoreRed.opacity(0.25), theme.palette.scoreRed.opacity(0)],
          startPoint: .top, endPoint: .bottom))
        .blur(radius: 8)
        .offset(y: 6)
        .padding(.horizontal, -2)

      VStack(spacing: 0) {
        TipRow(icon: "iphone", text: Strings.sessionPrestartTipPhone)
        Divider()
          .background(theme.palette.border)
          .padding(.leading, 52)
        TipRow(icon: "bolt.fill", text: Strings.sessionPrestartTipPluggedIn)
      }
      .background(theme.palette.bgCard)
      .clipShape(.rect(cornerRadius: theme.radii.card))
    }
  }

  private struct TipRow: View {
    let icon: String
    let text: String
    @Environment(\.theme) private var theme

    var body: some View {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 18))
          .foregroundStyle(theme.palette.accent)
          .frame(width: 24)
          .accessibilityHidden(true)
        Text(text)
          .font(theme.typography.font(size: 16))
          .foregroundStyle(theme.palette.textSecondary)
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
    }
  }
}

// MARK: - Bedside clock

/// "N EVENTS" in a green outlined capsule.
public struct BedsideEventsBadge: View {
  let count: Int
  @Environment(\.theme) private var theme

  public init(count: Int) {
    self.count = count
  }

  public var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(theme.palette.scoreGreen)
        .frame(width: 8, height: 8)
      Text(String(format: Strings.sessionRecordingEventsCountUpperFormat, count))
        .font(theme.typography.font(size: 13, weight: .semibold))
        .foregroundStyle(theme.palette.scoreGreen)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .overlay(Capsule().stroke(theme.palette.scoreGreen, lineWidth: 1))
  }
}

/// The big dim clock and the date under it.
public struct BedsideClockFace: View {
  let time: Date
  @Environment(\.theme) private var theme

  public init(time: Date) {
    self.time = time
  }

  public var body: some View {
    VStack(spacing: 8) {
      Text(Self.timeText(time))
        .font(.system(size: 96, weight: .thin, design: .rounded))
        .foregroundStyle(theme.palette.textTertiary)
        .minimumScaleFactor(0.5)
        .monospacedDigit()
      Text(Self.dateText(time))
        .font(theme.typography.font(size: 15, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
        .tracking(2)
    }
  }

  /// The device's short time ("23:41", "11:41 PM").
  static func timeText(_ time: Date) -> String {
    time.formatted(date: .omitted, time: .shortened)
  }

  /// Weekday, month and day for the locale, upper-cased ("MON NOV 16").
  static func dateText(_ time: Date) -> String {
    time.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased()
  }
}

/// "Recording · 1 h 12 min" and a level meter driven by the current level.
public struct BedsideRecordingStatus: View {
  let elapsed: TimeInterval
  let db: Float
  let time: Date
  @Environment(\.theme) private var theme

  /// `db`: the latest RMS level, dBFS. `time` moves the meter's ripple.
  public init(elapsed: TimeInterval, db: Float, time: Date) {
    self.elapsed = elapsed
    self.db = db
    self.time = time
  }

  public var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 6) {
        Circle()
          .fill(theme.palette.scoreGreen)
          .frame(width: 8, height: 8)
        Text(String(format: Strings.sessionRecordingStatusFormat, Self.elapsedText(elapsed)))
          .font(theme.typography.font(size: 16, weight: .medium))
          .foregroundStyle(theme.palette.accent)
          .monospacedDigit()
      }
      AudioLevelMeter(levels: Self.levels(db: db, time: time))
    }
  }

  /// "1 h 12 min", or "12 min" under an hour (SleepGuard's wording).
  static func elapsedText(_ elapsed: TimeInterval) -> String {
    let total = max(0, Int(elapsed))
    let (hours, minutes) = (total / 3600, total % 3600 / 60)
    return hours > 0 ? String(format: "%d h %d min", hours, minutes) : String(format: "%d min", minutes)
  }

  /// Nine bars around the level (−60 dBFS empty, −20 full), rippled by time.
  static func levels(db: Float, time: Date) -> [Double] {
    let base = Double(max(0, (db + 60) / 40))
    return (0..<9).map { index in
      let ripple = sin(Double(index) * 1.3 + time.timeIntervalSince1970 * 5) * 0.3
      return max(0.1, min(1, base + ripple))
    }
  }
}

/// The current snoring tier, in its colour.
public struct BedsideSnoreStatus: View {
  let state: DetectionState
  @Environment(\.theme) private var theme

  public init(state: DetectionState) {
    self.state = state
  }

  public var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "speaker.wave.2.fill")
        .font(.system(size: 14))
        .accessibilityHidden(true)
      Text(Self.label(state))
        .font(theme.typography.font(size: 15, weight: .medium))
    }
    .foregroundStyle(Self.color(state, palette: theme.palette))
  }

  static func label(_ state: DetectionState) -> String {
    switch state {
    case .none: Strings.statsCalendarIntensityQuiet
    case .quiet: Strings.sessionBedsideSnoreQuiet
    case .light: Strings.sessionBedsideSnoreLight
    case .loud: Strings.sessionBedsideSnoreLoud
    case .epic: Strings.sessionBedsideSnoreEpic
    }
  }

  static func color(_ state: DetectionState, palette: Palette) -> Color {
    switch state {
    case .none: palette.textTertiary
    case .quiet: palette.snoreQuiet
    case .light: palette.snoreLight
    case .loud: palette.snoreLoud
    case .epic: palette.snoreEpic
    }
  }
}

// MARK: - Summary

public extension NightTimeline {
  /// The night's displayable snoring episodes and its other events, its gaps,
  /// start and end, from SleepCore's rules.
  init(night: Night, showsTitle: Bool = true) {
    let episodes = night.displayableEpisodes.map {
      TimelineMark(start: $0.start, duration: $0.snoreDuration, category: .snoring, intensity: $0.intensity)
    }
    let others = night.events.filter { $0.category != .snoring }.map {
      TimelineMark(start: $0.start, duration: $0.duration, category: $0.category, intensity: $0.intensity)
    }
    self.init(
      start: night.start, end: night.end, marks: (episodes + others).sorted { $0.start < $1.start },
      gaps: night.recordingGaps, eventCount: night.eventCount, snoringDuration: night.snoringDuration,
      showsTitle: showsTitle)
  }
}

/// "SESSION COMPLETE", "You slept …", the score gauge, and the snoring and
/// events cards.
public struct SessionSummaryHeader: View {
  let duration: TimeInterval
  let score: Int
  let snoringPercent: Double
  let eventCount: Int
  @Environment(\.theme) private var theme

  public init(duration: TimeInterval, score: Int, snoringPercent: Double, eventCount: Int) {
    self.duration = duration
    self.score = score
    self.snoringPercent = snoringPercent
    self.eventCount = eventCount
  }

  public var body: some View {
    VStack(spacing: 32) {
      VStack(spacing: 8) {
        Text(Strings.sessionSummaryTitle)
          .font(theme.typography.font(size: 13, weight: .semibold))
          .foregroundStyle(theme.palette.scoreGreen)
          .tracking(2)
        Text(String(format: Strings.sessionSummaryYouSleptFormat, BedsideRecordingStatus.elapsedText(duration)))
          .font(theme.typography.font(size: 28, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
      }
      .padding(.top, 16)

      SleepScoreGauge(score: score, size: 160)

      HStack(spacing: 12) {
        StatCard(
          icon: "percent", title: Strings.sessionSummaryStatSnoring,
          value: String(format: "%.0f%%", snoringPercent), iconColor: theme.palette.scoreAmber)
        StatCard(
          icon: "bolt.fill", title: Strings.recordingsDetailEventsLabel,
          value: "\(eventCount)", iconColor: theme.palette.scoreAmber)
      }
    }
  }
}

/// The glowing "Save Session" capsule and the plain Discard button.
public struct SessionSummaryActions: View {
  let onSave: () -> Void
  let onDiscard: () -> Void
  @Environment(\.theme) private var theme

  public init(onSave: @escaping () -> Void, onDiscard: @escaping () -> Void) {
    self.onSave = onSave
    self.onDiscard = onDiscard
  }

  public var body: some View {
    VStack(spacing: 12) {
      ZStack {
        Capsule()
          .fill(theme.palette.accent.opacity(0.12))
          .frame(maxWidth: .infinity)
          .frame(height: 96)
          .blur(radius: 20)
          .offset(y: 6)
        Capsule()
          .fill(LinearGradient(
            colors: [theme.palette.accent.opacity(0.35), theme.palette.accent.opacity(0)],
            startPoint: .top, endPoint: .bottom))
          .frame(maxWidth: .infinity)
          .frame(height: 76)
          .blur(radius: 10)
          .offset(y: 8)
        Button(action: onSave) {
          Text(Strings.actionSaveSession)
            .font(theme.typography.font(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
              ZStack {
                Color(hex: "#1E1D1E")
                Capsule().stroke(
                  LinearGradient(
                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                    startPoint: .leading, endPoint: .trailing),
                  lineWidth: 1)
              }
            }
            .clipShape(Capsule())
        }
      }
      Button(action: onDiscard) {
        Text(Strings.actionDiscard)
          .font(theme.typography.font(size: 17, weight: .medium))
          .foregroundStyle(theme.palette.textSecondary)
      }
    }
  }
}
