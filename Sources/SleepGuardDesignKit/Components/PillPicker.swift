import SwiftUI

/// A few options side by side; the selected one is filled with the accent.
public struct PillPicker<Option: Hashable>: View {
  let options: [Option]
  @Binding var selection: Option
  let title: (Option) -> String
  @Environment(\.theme) private var theme

  public init(options: [Option], selection: Binding<Option>, title: @escaping (Option) -> String) {
    self.options = options
    _selection = selection
    self.title = title
  }

  public var body: some View {
    HStack(spacing: 0) {
      ForEach(options, id: \.self) { option in
        Button {
          withAnimation(.easeInOut(duration: 0.2)) { selection = option }
        } label: {
          Text(title(option))
            .font(theme.typography.font(size: 13, weight: .semibold))
            .foregroundStyle(selection == option ? Color.white : theme.palette.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(selection == option ? theme.palette.accent : .clear, in: .rect(cornerRadius: 8))
        }
        .accessibilityAddTraits(selection == option ? .isSelected : [])
      }
    }
    .background(theme.palette.bgCard, in: .rect(cornerRadius: 8))
  }
}
