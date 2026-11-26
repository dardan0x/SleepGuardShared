import SleepCore
import SwiftUI
import SleepGuardDesignKit

/// The Snore Interrupter's rows, sheets and bedside pieces with sample values,
/// for previews and render tests. Internal: sample data only.
struct SnoreInterrupterContentGallery: View {
  enum Screen: CaseIterable {
    case prestartOptions
    case settings
    case picker
    case recording
    case recorded
    case bedside
  }

  let screen: Screen

  static let custom = [Melody(id: 100, filename: "custom_100.m4a", customName: Melody.customName(number: 1))]

  var body: some View {
    VStack(spacing: 16) {
      switch screen {
      case .prestartOptions:
        PrestartOptions(delayMinutes: .constant(15), interrupterMode: .fifteenSeconds) {}
      case .settings:
        SnoreInterrupterSettingsStack(
          mode: .constant(.thirtySeconds), melodyName: Melody.resolve(id: 6, custom: []).name) {}
      case .picker:
        MelodyPickerList(
          custom: Self.custom, selectedID: 6, previewingID: 2, onRecord: {}, onSelect: { _ in }, onDelete: { _ in })
      case .recording:
        RecordMelodyControls(state: .recording, elapsed: 4.7, canRecord: true, onRecordToggle: {}, onPlayToggle: {})
      case .recorded:
        RecordMelodyControls(
          state: .recorded(isPlaying: false), elapsed: 6.2, canRecord: true, onRecordToggle: {}, onPlayToggle: {})
      case .bedside:
        BedsideMelodyDisclaimer {}
        BedsideMelodyOverlay(melodyName: Melody.resolve(id: 4, custom: []).name, onMute: {}, onStop: {})
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .background(InterrupterGalleryBackground())
  }
}

private struct InterrupterGalleryBackground: View {
  @Environment(\.theme) private var theme

  var body: some View {
    theme.palette.bgPrimary
  }
}

#Preview("Settings") {
  SnoreInterrupterSettingsContent(mode: .constant(.fifteenSeconds), melodyName: "Attention Chime", onSound: {}, onSave: {}, onCancel: {})
}

#Preview("Picker") {
  MelodyPickerContent(
    custom: SnoreInterrupterContentGallery.custom, selectedID: 6, previewingID: nil, onRecord: {},
    onSelect: { _ in }, onDelete: { _ in }, onDone: {})
}

#Preview("Record") {
  RecordMelodyContent(
    state: .recorded(isPlaying: false), elapsed: 6.2, canRecord: true, onRecordToggle: {}, onPlayToggle: {},
    onSave: {}, onReRecord: {}, onBack: {})
}
