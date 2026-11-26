import SleepCore
import SwiftUI
import SleepGuardDesignKit
import SleepStrings

/// Choosing the interrupter's sound: record your own, then your recordings,
/// then the built-ins. Tapping one chooses and previews it; the screen plays
/// the preview and says which one is playing (`previewingID`).
public struct MelodyPickerContent: View {
  let custom: [Melody]
  let selectedID: Int
  let previewingID: Int?
  let onRecord: () -> Void
  let onSelect: (Melody) -> Void
  let onDelete: (Melody) -> Void
  let onDone: () -> Void
  @Environment(\.theme) private var theme

  public init(
    custom: [Melody], selectedID: Int, previewingID: Int?, onRecord: @escaping () -> Void,
    onSelect: @escaping (Melody) -> Void, onDelete: @escaping (Melody) -> Void, onDone: @escaping () -> Void)
  {
    self.custom = custom
    self.selectedID = selectedID
    self.previewingID = previewingID
    self.onRecord = onRecord
    self.onSelect = onSelect
    self.onDelete = onDelete
    self.onDone = onDone
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button(action: onDone) {
          Label(Strings.actionBack, systemImage: "chevron.left")
            .labelStyle(.iconOnly)
            .font(.system(size: 17))
            .foregroundStyle(theme.palette.accent)
        }
        .buttonStyle(.plain)
        Spacer()
      }
      .frame(height: 44)
      .padding(.horizontal, 16)
      ScrollView {
        MelodyPickerList(
          custom: custom, selectedID: selectedID, previewingID: previewingID,
          onRecord: onRecord, onSelect: onSelect, onDelete: onDelete)
          .padding(.horizontal, 16)
          .padding(.top, 4)
          .padding(.bottom, 8)
      }
      Divider().background(theme.palette.border)
      Button(action: onDone) {
        Text(Strings.saveMelodyPickerSheet)
          .font(theme.typography.font(size: 15, weight: .bold))
          .tracking(1.5)
          .foregroundStyle(theme.palette.textPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 66)
      }
      .buttonStyle(.plain)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }
}

/// The picker's rows (render tests draw this).
struct MelodyPickerList: View {
  let custom: [Melody]
  let selectedID: Int
  let previewingID: Int?
  let onRecord: () -> Void
  let onSelect: (Melody) -> Void
  let onDelete: (Melody) -> Void

  var body: some View {
    VStack(spacing: 8) {
      RecordMelodyRow(action: onRecord)
      ForEach(custom + Melody.builtIn) { melody in
        MelodyRow(
          melody: melody, isSelected: melody.id == selectedID, isPreviewing: melody.id == previewingID,
          onTap: { onSelect(melody) }, onDelete: { onDelete(melody) })
      }
    }
  }
}
