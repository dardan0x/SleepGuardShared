import SleepCore
import SwiftUI

/// Quiet, light and loud dots with their names: the key for snoring colours.
public struct SnoringLegend: View {
  @Environment(\.theme) private var theme

  public init() {}

  public var body: some View {
    HStack(spacing: 16) {
      item(.quiet, Strings.statsCalendarIntensityQuiet)
      item(.light, Strings.settingsThemeLight)
      item(.loud, Strings.statsCalendarIntensityLoud)
    }
    .frame(maxWidth: .infinity)
  }

  private func item(_ intensity: SnoreIntensity, _ label: String) -> some View {
    HStack(spacing: 4) {
      Circle().fill(theme.palette.eventColor(.snoring, intensity: intensity)).frame(width: 6, height: 6)
      Text(label)
        .font(theme.typography.font(size: 12))
        .foregroundStyle(theme.palette.textSecondary)
    }
  }
}
