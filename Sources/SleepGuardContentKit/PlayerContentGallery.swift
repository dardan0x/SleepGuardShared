import SleepCore
import SwiftUI

/// The player content with sample clips, for previews and render tests.
/// Internal: sample data only.
struct PlayerContentGallery: View {
  enum Screen: CaseIterable {
    case playing
    case loading
  }

  let screen: Screen
  @State private var enhanced = true
  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  static let clips: [PlayerClip] = [
    PlayerClip(id: UUID(), start: start, duration: 45, category: .snoring, intensity: .light),
    PlayerClip(id: UUID(), start: start.addingTimeInterval(60), duration: 80, category: .snoring, intensity: .loud),
    PlayerClip(id: UUID(), start: start.addingTimeInterval(3600), duration: 12, category: .sleepTalking, intensity: .quiet),
  ]

  static let waveform: [Float] = (0..<300).map { index in
    let wave: Double = abs(sin(Double(index) / 9))
    let swell = 0.4 + 0.6 * Double(index % 50) / 50
    return Float(wave * swell)
  }

  var body: some View {
    PlayerContent(
      clips: Self.clips, index: 1, isPlaying: true, currentTime: 70, totalDuration: 137,
      waveform: screen == .playing ? Self.waveform : [], isLoadingWaveform: screen == .loading,
      isReady: screen == .playing, isEnhanced: $enhanced, onToggle: {}, onSeek: { _ in }, onSelect: { _ in })
      .padding(20)
      .background(PlayerContentBackground())
  }
}

private struct PlayerContentBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Player") {
  ScrollView { PlayerContentGallery(screen: .playing) }
}

#Preview("Player loading") {
  ScrollView { PlayerContentGallery(screen: .loading) }
    .environment(\.theme, .previewAlternate)
}
