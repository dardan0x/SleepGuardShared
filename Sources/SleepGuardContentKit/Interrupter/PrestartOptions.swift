import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// The prestart's options: the start delay and, for an app with the Snore
/// Interrupter, its row and the note under it. Goes in `PrestartContent`'s
/// options slot.
public struct PrestartOptions: View {
  @Binding var delayMinutes: Int
  let interrupterMode: SnoreInterrupterMode?
  let onInterrupter: () -> Void
  @Environment(\.theme) private var theme

  /// `interrupterMode` is `nil` without the interrupter: no row, no note.
  public init(
    delayMinutes: Binding<Int>, interrupterMode: SnoreInterrupterMode?, onInterrupter: @escaping () -> Void)
  {
    _delayMinutes = delayMinutes
    self.interrupterMode = interrupterMode
    self.onInterrupter = onInterrupter
  }

  public var body: some View {
    VStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        PrestartDelayOptions(minutes: $delayMinutes)
        if let interrupterMode {
          SnoreInterrupterRow(mode: interrupterMode, action: onInterrupter)
            .padding(.top, 8)
        }
      }
      if interrupterMode != nil {
        Text(Strings.snoreInterrupterRowHelperText)
          .font(theme.typography.font(size: 14))
          .foregroundStyle(theme.palette.textTertiary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
      }
    }
  }
}
