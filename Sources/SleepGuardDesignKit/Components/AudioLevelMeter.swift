import SwiftUI

/// Live level bars, coloured quiet / light / loud. Decorative: hidden from VoiceOver.
public struct AudioLevelMeter: View {
  /// 0…1 per bar.
  let levels: [Double]
  @Environment(\.theme) private var theme

  public init(levels: [Double]) {
    self.levels = levels
  }

  public var body: some View {
    HStack(alignment: .center, spacing: 6) {
      ForEach(levels.indices, id: \.self) { index in
        RoundedRectangle(cornerRadius: 3)
          .fill(barColor(for: levels[index]))
          .frame(width: 8, height: CGFloat(levels[index]) * 80)
      }
    }
    .frame(height: 80)
    .accessibilityHidden(true)
  }

  private func barColor(for level: Double) -> Color {
    if level > 0.7 {
      theme.palette.snoreLoud
    } else if level > 0.4 {
      theme.palette.snoreLight
    } else {
      theme.palette.snoreQuiet
    }
  }
}
