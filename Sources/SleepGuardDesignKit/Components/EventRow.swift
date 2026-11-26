import SleepCore
import SwiftUI
import SleepStrings

/// One event (or snoring episode) in a list: kind, start time, length, and
/// Share / Play buttons when those actions are given.
public struct EventRow: View {
  let start: Date
  let duration: TimeInterval
  let category: SoundCategory
  let intensity: SnoreIntensity
  let onPlay: (() -> Void)?
  let onShare: (() -> Void)?
  @Environment(\.theme) private var theme

  public init(
    start: Date, duration: TimeInterval, category: SoundCategory, intensity: SnoreIntensity,
    onPlay: (() -> Void)? = nil, onShare: (() -> Void)? = nil)
  {
    self.start = start
    self.duration = duration
    self.category = category
    self.intensity = intensity
    self.onPlay = onPlay
    self.onShare = onShare
  }

  public var body: some View {
    HStack(spacing: 12) {
      EventKindIndicator(category: category, intensity: intensity)
      Text(start.formatted(date: .omitted, time: .shortened))
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(theme.palette.textPrimary)
        .monospacedDigit()
      Text(Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)))
        .font(theme.typography.font(size: 14, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
        .monospacedDigit()
      Spacer()
      if let onShare {
        Button(action: onShare) {
          Label(Strings.a11yShare, systemImage: "square.and.arrow.up").labelStyle(.iconOnly)
            .font(.system(size: 14))
            .foregroundStyle(theme.palette.textTertiary)
        }
      }
      if let onPlay {
        Button(action: onPlay) {
          Label(Strings.actionPlay, systemImage: "play.fill").labelStyle(.iconOnly)
            .font(.system(size: 14))
            .foregroundStyle(theme.palette.accent)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    .contentShape(Rectangle())
    .onTapGesture { onPlay?() }
  }
}

/// Snoring: a dot in the intensity colour. Sleep talking: a speech bubble. Noise: a waveform.
struct EventKindIndicator: View {
  let category: SoundCategory
  let intensity: SnoreIntensity
  @Environment(\.theme) private var theme

  var body: some View {
    let color = theme.palette.eventColor(category, intensity: intensity)
    Group {
      switch category {
      case .snoring:
        Circle().fill(color).frame(width: 10, height: 10)
      case .sleepTalking:
        Image(systemName: "bubble.left.fill").font(.system(size: 11, weight: .semibold)).foregroundStyle(color)
      case .noise, .coughing, .other:
        Image(systemName: "waveform").font(.system(size: 11, weight: .semibold)).foregroundStyle(color)
      }
    }
    .frame(width: 12, height: 12)
    .accessibilityHidden(true)
  }
}
