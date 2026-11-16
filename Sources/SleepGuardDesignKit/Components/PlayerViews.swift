import SleepCore
import SwiftUI

extension SnoreIntensity {
  /// "Quiet", "Light", "Loud", "Epic".
  var label: String {
    switch self {
    case .quiet: Strings.quietIntensityLabel
    case .light: Strings.lightIntensityLabelEventPlayerView
    case .loud: Strings.loudIntensityLabelEventPlayerView
    case .epic: Strings.epicIntensityLabelEventPlayerView
    }
  }
}

/// The playing event: time, "SNORING EVENT", length · loudness, and which of
/// several events it is.
public struct PlayerHeader: View {
  let start: Date
  let duration: TimeInterval
  let intensity: SnoreIntensity
  let number: Int
  let count: Int
  @Environment(\.theme) private var theme

  public init(start: Date, duration: TimeInterval, intensity: SnoreIntensity, number: Int, count: Int) {
    self.start = start
    self.duration = duration
    self.intensity = intensity
    self.number = number
    self.count = count
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(start.formatted(date: .omitted, time: .shortened))
        .font(theme.typography.font(size: 13, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
      Text(Strings.snoringEventHeaderPlayerView.uppercased())
        .font(theme.typography.font(size: 11, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .tracking(1.5)
      HStack(spacing: 8) {
        Text(Duration.seconds(duration).formatted(.units(allowed: [.minutes, .seconds], width: .narrow)))
          .foregroundStyle(theme.palette.textPrimary)
        Text("·").foregroundStyle(theme.palette.textSecondary)
        Text(intensity.label).foregroundStyle(theme.palette.eventColor(.snoring, intensity: intensity))
      }
      .font(.system(size: 22, weight: .bold, design: .rounded))
      if count > 1 {
        Text("\(Strings.eventHeaderSectionTotalEvents) \(number) / \(count)")
          .font(theme.typography.font(size: 12, weight: .medium))
          .foregroundStyle(theme.palette.textTertiary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Back 15 s, play or pause, forward 15 s.
public struct PlayerControls: View {
  let isPlaying: Bool
  let onToggle: () -> Void
  let onBack: () -> Void
  let onForward: () -> Void
  @Environment(\.theme) private var theme

  public init(isPlaying: Bool, onToggle: @escaping () -> Void, onBack: @escaping () -> Void, onForward: @escaping () -> Void) {
    self.isPlaying = isPlaying
    self.onToggle = onToggle
    self.onBack = onBack
    self.onForward = onForward
  }

  public var body: some View {
    HStack(spacing: 40) {
      Button(action: onBack) {
        Label(Strings.a11ySkipBack15, systemImage: "gobackward.15").labelStyle(.iconOnly)
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.palette.textPrimary)
      }
      Button(action: onToggle) {
        Label(isPlaying ? Strings.a11yPause : Strings.actionPlay, systemImage: isPlaying ? "pause.fill" : "play.fill")
          .labelStyle(.iconOnly)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.palette.bgPrimary)
          .frame(width: 72, height: 72)
          .background(Color.white, in: .circle)
      }
      Button(action: onForward) {
        Label(Strings.a11ySkipForward15, systemImage: "goforward.15").labelStyle(.iconOnly)
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(theme.palette.textPrimary)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

/// An event in the player's list: kind, time span, length and loudness; the
/// playing one is highlighted.
public struct PlayerEventRow: View {
  let start: Date
  let duration: TimeInterval
  let category: SoundCategory
  let intensity: SnoreIntensity
  let isActive: Bool
  let isPlaying: Bool
  let onTap: () -> Void
  @Environment(\.theme) private var theme

  public init(
    start: Date, duration: TimeInterval, category: SoundCategory, intensity: SnoreIntensity,
    isActive: Bool, isPlaying: Bool, onTap: @escaping () -> Void)
  {
    self.start = start
    self.duration = duration
    self.category = category
    self.intensity = intensity
    self.isActive = isActive
    self.isPlaying = isPlaying
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        EventKindIndicator(category: category, intensity: intensity)
        VStack(alignment: .leading, spacing: 2) {
          Text("\(start.formatted(date: .omitted, time: .shortened)) – \(start.addingTimeInterval(duration).formatted(date: .omitted, time: .shortened))")
            .font(theme.typography.font(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? theme.palette.accent : theme.palette.textPrimary)
          Text("\(Duration.seconds(duration).formatted(.units(allowed: [.minutes, .seconds], width: .narrow))) · \(intensity.label)")
            .font(theme.typography.font(size: 12))
            .foregroundStyle(theme.palette.textSecondary)
        }
        Spacer()
        if isActive, isPlaying {
          Image(systemName: "waveform")
            .font(.system(size: 14))
            .foregroundStyle(theme.palette.accent)
            .accessibilityHidden(true)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .background(isActive ? theme.palette.accent.opacity(0.10) : theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isActive ? .isSelected : [])
  }
}

/// "Enhanced Audio": band-pass and boost at playback.
public struct EnhancedAudioToggle: View {
  @Binding var isOn: Bool
  @Environment(\.theme) private var theme

  public init(isOn: Binding<Bool>) {
    _isOn = isOn
  }

  public var body: some View {
    Toggle(isOn: $isOn) {
      VStack(alignment: .leading, spacing: 2) {
        Text(Strings.eventPlayerEnhancedAudioLabel)
          .font(theme.typography.font(size: 15, weight: .medium))
          .foregroundStyle(theme.palette.textPrimary)
        Text(Strings.eventPlayerEnhancedAudioDescription)
          .font(theme.typography.font(size: 12))
          .foregroundStyle(theme.palette.textSecondary)
      }
    }
    .tint(theme.palette.accent)
    .padding(16)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }
}

/// The event has no playable audio: why, and which event it was.
public struct NoAudioCard: View {
  let start: Date
  let duration: TimeInterval
  let intensity: SnoreIntensity
  @Environment(\.theme) private var theme

  public init(start: Date, duration: TimeInterval, intensity: SnoreIntensity) {
    self.start = start
    self.duration = duration
    self.intensity = intensity
  }

  public var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 44))
        .foregroundStyle(theme.palette.textTertiary)
        .accessibilityHidden(true)
      Text(Strings.eventPlayerNoAudioTitle)
        .font(theme.typography.font(size: 18, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)
      Text(Strings.eventPlayerNoAudioDescription)
        .font(theme.typography.font(size: 14))
        .foregroundStyle(theme.palette.textSecondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Text("\(start.formatted(date: .omitted, time: .shortened)) · \(Duration.seconds(duration).formatted(.units(allowed: [.minutes, .seconds], width: .narrow))) · \(intensity.label)")
        .font(theme.typography.font(size: 13, weight: .medium))
        .foregroundStyle(theme.palette.textTertiary)
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }
}

/// The four snoring loudness colours with their names.
public struct EventIntensityLegend: View {
  @Environment(\.theme) private var theme

  public init() {}

  public var body: some View {
    HStack(spacing: 14) {
      ForEach([SnoreIntensity.quiet, .light, .loud, .epic], id: \.self) { intensity in
        HStack(spacing: 4) {
          Circle().fill(theme.palette.eventColor(.snoring, intensity: intensity)).frame(width: 8, height: 8)
          Text(intensity.label)
            .font(theme.typography.font(size: 12, weight: .medium))
            .foregroundStyle(theme.palette.textSecondary)
        }
      }
    }
  }
}
