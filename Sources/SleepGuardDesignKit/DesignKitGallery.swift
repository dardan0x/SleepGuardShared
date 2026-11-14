import SwiftUI

/// Every component on one screen, for previews and render tests. Internal:
/// its sample labels are preview data, not product strings.
struct DesignKitGallery: View {
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 16) {
      SheetHandle()
      SleepScoreGauge(score: 82, size: 120)
      HStack(spacing: 8) {
        StatCard(icon: "moon.fill", title: "Duration", value: "7h 42m")
        StatCard(icon: "waveform", title: "Snoring", value: "12%", iconColor: theme.palette.snoreLight)
      }
      MiniBarChart(data: [64, 71, 58, 82, 77, 49, 88].enumerated().map { index, score in
        .init(label: ["M", "T", "W", "T", "F", "S", "S"][index], value: Double(score), color: theme.scoreColor(score))
      })
      AudioLevelMeter(levels: [0.2, 0.35, 0.5, 0.8, 0.6, 0.3, 0.45, 0.9, 0.25])
      StartRecordingButton {}
      StopRecordingButton {}
    }
    .padding(16)
    .background(theme.palette.bgPrimary)
  }
}

extension Theme {
  /// A deliberately different theme, to check that components take every
  /// colour, font and radius from the theme. Not a product theme.
  static let previewAlternate: Theme = {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#120A24")
    theme.palette.bgCard = Color(hex: "#221640")
    theme.palette.bgElevated = Color(hex: "#3A2C66")
    theme.palette.accent = Color(hex: "#9B7BFF")
    theme.palette.destructive = Color(hex: "#FFB547")
    theme.typography = Typography(design: .rounded)
    theme.radii = Radii(card: 24, small: 16)
    return theme
  }()
}

#Preview("SleepGuard") {
  DesignKitGallery()
}

#Preview("Alternate theme") {
  DesignKitGallery()
    .environment(\.theme, .previewAlternate)
}
