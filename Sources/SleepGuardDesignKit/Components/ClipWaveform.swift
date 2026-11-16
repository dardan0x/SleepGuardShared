import SwiftUI

/// The playing clip as bars, played ones in the accent colour, a playhead,
/// and the time labels. Tap to seek. While `isLoading`, placeholder bars
/// pulse. SleepGuard's event waveform.
public struct ClipWaveform: View {
  let samples: [Float]
  let currentTime: TimeInterval
  let totalDuration: TimeInterval
  let isLoading: Bool
  let onSeek: (Double) -> Void
  @State private var pulse = false
  @Environment(\.theme) private var theme

  /// `samples`: 0...1 bars (SleepCore's `WaveformAccumulator`). `onSeek`
  /// gets the tapped position, 0...1.
  public init(samples: [Float], currentTime: TimeInterval, totalDuration: TimeInterval, isLoading: Bool, onSeek: @escaping (Double) -> Void) {
    self.samples = samples
    self.currentTime = currentTime
    self.totalDuration = totalDuration
    self.isLoading = isLoading
    self.onSeek = onSeek
  }

  public var body: some View {
    VStack(spacing: 12) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          if isLoading {
            bars(height: geometry.size.height, played: 0) { index, height in
              max(CGFloat((index * 7 + 13) % 17) / 16 * height * 0.55, 4)
            }
            .opacity(pulse ? 0.25 : 0.55)
          } else {
            bars(height: geometry.size.height, played: progress) { index, height in
              Self.barHeight(index: index, of: barCount, samples: samples, maxHeight: height)
            }
            Rectangle()
              .fill(Color.white)
              .frame(width: 2, height: geometry.size.height + 8)
              .offset(x: CGFloat(progress) * geometry.size.width - 1)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
          guard !isLoading, geometry.size.width > 0 else { return }
          onSeek(Double(location.x / geometry.size.width))
        }
      }
      .frame(height: 80)
      .accessibilityElement()
      .accessibilityLabel(Strings.snoringEventHeaderPlayerView)
      .accessibilityValue("\(PlayerTime.clock(currentTime)) / \(PlayerTime.clock(totalDuration))")
      .accessibilityAdjustableAction { direction in
        guard totalDuration > 0 else { return }
        let step = direction == .increment ? 15.0 : -15.0
        onSeek(min(max((currentTime + step) / totalDuration, 0), 1))
      }

      HStack {
        Text(PlayerTime.clock(0))
        Spacer()
        Text("\(PlayerTime.clock(currentTime)) / \(PlayerTime.clock(totalDuration))")
        Spacer()
        Text(PlayerTime.clock(totalDuration))
      }
      .font(.system(size: 12, weight: .medium, design: .monospaced))
      .foregroundStyle(theme.palette.textSecondary)
      .monospacedDigit()
      .accessibilityHidden(true)
    }
    .task(id: isLoading) {
      guard isLoading else { return }
      while !Task.isCancelled {
        withAnimation(.easeInOut(duration: 0.7)) { pulse.toggle() }
        try? await Task.sleep(for: .seconds(0.7))
      }
    }
  }

  private func bars(height: CGFloat, played: Double, barHeight: @escaping (Int, CGFloat) -> CGFloat) -> some View {
    HStack(alignment: .center, spacing: 2) {
      ForEach(0..<barCount, id: \.self) { index in
        RoundedRectangle(cornerRadius: 1.5)
          .fill(Double(index) / Double(barCount) <= played && played > 0 ? theme.palette.accent : theme.palette.bgElevated)
          .frame(maxWidth: .infinity)
          .frame(height: barHeight(index, height))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  /// 40 to 80 bars, as many as the samples allow.
  private var barCount: Int {
    max(min(samples.count, 80), 40)
  }

  private var progress: Double {
    totalDuration > 0 ? currentTime / totalDuration : 0
  }

  /// The sample under bar `index`, as a height (3 pt at least).
  static func barHeight(index: Int, of barCount: Int, samples: [Float], maxHeight: CGFloat) -> CGFloat {
    guard !samples.isEmpty else { return 2 }
    let sampleIndex = Int(Double(index) / Double(barCount) * Double(samples.count))
    guard samples.indices.contains(sampleIndex) else { return 2 }
    return max(CGFloat(samples[sampleIndex]) * maxHeight * 0.9, 3)
  }
}

/// "m:ss" for the player's times.
enum PlayerTime {
  static func clock(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}
