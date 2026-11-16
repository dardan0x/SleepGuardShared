import SleepCore
import SwiftUI

/// The player components on one screen, for previews and render tests.
/// Internal: sample data only.
struct PlayerGallery: View {
  @Environment(\.theme) private var theme
  @State private var enhanced = true
  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 24) {
        PlayerHeader(start: Self.start, duration: 125, intensity: .loud, number: 2, count: 3)
        ClipWaveform(samples: (0..<120).map { Float(abs(sin(Double($0) / 6))) }, currentTime: 48, totalDuration: 125, isLoading: false) { _ in }
        PlayerControls(isPlaying: true, onToggle: {}, onBack: {}, onForward: {})
        EventIntensityLegend()
      }
      .padding(20)
      .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
      EnhancedAudioToggle(isOn: $enhanced)
      PlayerEventRow(start: Self.start, duration: 45, category: .snoring, intensity: .light, isActive: false, isPlaying: true) {}
      PlayerEventRow(
        start: Self.start.addingTimeInterval(60), duration: 80, category: .snoring, intensity: .loud, isActive: true,
        isPlaying: true) {}
      NoAudioCard(start: Self.start, duration: 12, intensity: .quiet)
    }
    .padding(16)
    .background(theme.palette.bgPrimary)
  }
}

#Preview("SleepGuard") {
  PlayerGallery()
}

#Preview("Alternate theme") {
  PlayerGallery()
    .environment(\.theme, .previewAlternate)
}
