import SwiftUI
import SleepGuardDesignKit

/// The small caps label over a profile field.
struct ProfileFieldTitle: View {
  let text: String
  @Environment(\.theme) private var theme

  var body: some View {
    Text(text.uppercased())
      .font(theme.typography.font(size: 13, weight: .medium))
      .foregroundStyle(theme.palette.textTertiary)
      .lineLimit(1)
  }
}

/// A labelled text field. `number` brings up the number pad.
struct ProfileTextField: View {
  let title: String
  @Binding var text: String
  var number = false
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ProfileFieldTitle(text: title)
      TextField(text: $text) { Text(title) }
        .font(theme.typography.font(size: 17, weight: .medium))
        .foregroundStyle(theme.palette.textPrimary)
      #if os(iOS)
        .keyboardType(number ? .decimalPad : .default)
      #endif
        .padding(14)
        .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
    }
  }
}

/// A labelled row of chips; the chosen one is filled with the accent.
struct ProfileChoice<Value: Hashable>: View {
  let title: String
  let options: [(label: String, value: Value)]
  @Binding var selection: Value
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ProfileFieldTitle(text: title)
      FlowLayout(spacing: 8) {
        ForEach(options, id: \.value) { option in
          let isSelected = option.value == selection
          Button {
            selection = option.value
          } label: {
            Text(option.label)
              .font(theme.typography.font(size: 14, weight: .medium))
              .foregroundStyle(isSelected ? theme.palette.bgPrimary : theme.palette.textPrimary)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(
                isSelected ? theme.palette.accent : theme.palette.bgElevated,
                in: .rect(cornerRadius: theme.radii.small))
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
      }
    }
  }
}

/// A page's title and its fields, scrolling.
struct ProfilePage<Fields: View>: View {
  let title: String
  var spacing: CGFloat = 20
  @ViewBuilder let fields: Fields
  @Environment(\.profilePageScrolls) private var scrolls

  var body: some View {
    if scrolls {
      ScrollView {
        ProfilePageStack(title: title, spacing: spacing) { fields }
      }
      .scrollIndicators(.hidden)
    } else {
      ProfilePageStack(title: title, spacing: spacing) { fields }
    }
  }
}

extension EnvironmentValues {
  /// Off in render tests: `ImageRenderer` can't draw inside a `ScrollView`.
  @Entry var profilePageScrolls = true
}

/// The inside of a page (render tests draw this).
struct ProfilePageStack<Fields: View>: View {
  let title: String
  let spacing: CGFloat
  @ViewBuilder let fields: Fields
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: spacing) {
      Text(title)
        .font(theme.typography.font(size: 28, weight: .bold))
        .foregroundStyle(theme.palette.textPrimary)
        .accessibilityAddTraits(.isHeader)
      fields
      Spacer(minLength: 40)
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
