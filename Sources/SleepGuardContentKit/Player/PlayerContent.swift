import SleepCore
import SwiftUI

/// One clip in the player's list.
public struct PlayerClip: Identifiable, Equatable, Sendable {
  public let id: UUID
  public let start: Date
  public let duration: TimeInterval
  public let category: SoundCategory
  public let intensity: SnoreIntensity

  public init(id: UUID, start: Date, duration: TimeInterval, category: SoundCategory, intensity: SnoreIntensity) {
    self.id = id
    self.start = start
    self.duration = duration
    self.category = category
    self.intensity = intensity
  }
}

/// The player card: the playing event, its waveform with the playhead,
/// back / play / forward, and the loudness key. Until `isReady`, a "Loading
/// audio" veil covers it.
public struct PlayerCard: View {
  let clip: PlayerClip
  let number: Int
  let count: Int
  let isPlaying: Bool
  let currentTime: TimeInterval
  let totalDuration: TimeInterval
  let waveform: [Float]
  let isLoadingWaveform: Bool
  let isReady: Bool
  let onToggle: () -> Void
  let onBack: () -> Void
  let onForward: () -> Void
  let onSeek: (Double) -> Void
  @Environment(\.theme) private var theme

  /// `number` of `count`, from 1. Times are over every clip in the player.
  public init(
    clip: PlayerClip,
    number: Int,
    count: Int,
    isPlaying: Bool,
    currentTime: TimeInterval,
    totalDuration: TimeInterval,
    waveform: [Float],
    isLoadingWaveform: Bool,
    isReady: Bool = true,
    onToggle: @escaping () -> Void,
    onBack: @escaping () -> Void,
    onForward: @escaping () -> Void,
    onSeek: @escaping (Double) -> Void)
  {
    self.clip = clip
    self.number = number
    self.count = count
    self.isPlaying = isPlaying
    self.currentTime = currentTime
    self.totalDuration = totalDuration
    self.waveform = waveform
    self.isLoadingWaveform = isLoadingWaveform
    self.isReady = isReady
    self.onToggle = onToggle
    self.onBack = onBack
    self.onForward = onForward
    self.onSeek = onSeek
  }

  public var body: some View {
    ZStack {
      VStack(spacing: 24) {
        PlayerHeader(start: clip.start, duration: totalDuration, intensity: clip.intensity, number: number, count: count)
        ClipWaveform(
          samples: waveform, currentTime: currentTime, totalDuration: totalDuration, isLoading: isLoadingWaveform,
          onSeek: onSeek)
        PlayerControls(isPlaying: isPlaying, onToggle: onToggle, onBack: onBack, onForward: onForward)
        EventIntensityLegend()
      }
      .padding(20)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))

      if !isReady {
        VStack(spacing: 12) {
          ProgressView()
            .scaleEffect(1.2)
            .tint(theme.palette.accent)
          Text(Strings.loadingAudioEventPlayerView)
            .font(theme.typography.font(size: 14, weight: .medium))
            .foregroundStyle(theme.palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.palette.bgCard.opacity(0.95), in: .rect(cornerRadius: theme.radii.card))
      }
    }
  }

  /// Where back / forward lands: `seconds` from `currentTime`, as a position
  /// over `totalDuration` (0...1); `nil` without a length. Both apps' clip
  /// players skip 15 s this way.
  public static func position(skipping seconds: TimeInterval, from currentTime: TimeInterval, of totalDuration: TimeInterval) -> Double? {
    guard totalDuration > 0 else { return nil }
    return max(0, currentTime + seconds) / totalDuration
  }
}

/// The clip player's sheet below its title: the card, enhanced audio, and,
/// with several clips, the list to pick from.
public struct PlayerContent: View {
  let clips: [PlayerClip]
  let index: Int
  let isPlaying: Bool
  let currentTime: TimeInterval
  let totalDuration: TimeInterval
  let waveform: [Float]
  let isLoadingWaveform: Bool
  let isReady: Bool
  @Binding var isEnhanced: Bool
  let onToggle: () -> Void
  let onSeek: (Double) -> Void
  let onSelect: (Int) -> Void
  @Environment(\.theme) private var theme

  /// `index`: the playing clip in `clips`. Back and forward skip 15 s
  /// through `onSeek`.
  public init(
    clips: [PlayerClip],
    index: Int,
    isPlaying: Bool,
    currentTime: TimeInterval,
    totalDuration: TimeInterval,
    waveform: [Float],
    isLoadingWaveform: Bool,
    isReady: Bool = true,
    isEnhanced: Binding<Bool>,
    onToggle: @escaping () -> Void,
    onSeek: @escaping (Double) -> Void,
    onSelect: @escaping (Int) -> Void)
  {
    self.clips = clips
    self.index = index
    self.isPlaying = isPlaying
    self.currentTime = currentTime
    self.totalDuration = totalDuration
    self.waveform = waveform
    self.isLoadingWaveform = isLoadingWaveform
    self.isReady = isReady
    _isEnhanced = isEnhanced
    self.onToggle = onToggle
    self.onSeek = onSeek
    self.onSelect = onSelect
  }

  public var body: some View {
    if clips.indices.contains(index) {
      VStack(spacing: 24) {
        PlayerCard(
          clip: clips[index], number: index + 1, count: clips.count, isPlaying: isPlaying, currentTime: currentTime,
          totalDuration: totalDuration, waveform: waveform, isLoadingWaveform: isLoadingWaveform, isReady: isReady,
          onToggle: onToggle, onBack: { skip(-15) }, onForward: { skip(15) }, onSeek: onSeek)
        EnhancedAudioToggle(isOn: $isEnhanced)
        if clips.count > 1 {
          VStack(alignment: .leading, spacing: 12) {
            Text(Strings.recordingsDetailEventsLabel)
              .font(theme.typography.font(size: 12, weight: .semibold))
              .foregroundStyle(theme.palette.textTertiary)
              .tracking(1)
            VStack(spacing: 6) {
              ForEach(Array(clips.enumerated()), id: \.element.id) { offset, clip in
                PlayerEventRow(
                  start: clip.start, duration: clip.duration, category: clip.category, intensity: clip.intensity,
                  isActive: offset == index, isPlaying: isPlaying) { onSelect(offset) }
              }
            }
          }
        }
      }
    }
  }

  private func skip(_ seconds: TimeInterval) {
    if let position = PlayerCard.position(skipping: seconds, from: currentTime, of: totalDuration) {
      onSeek(position)
    }
  }
}
