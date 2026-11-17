import SwiftUI

/// The card on Statistics that asks for the profile ("Make this yours"). The
/// screen decides when it shows (`ProfilePrompt.shouldShow`). Set Up opens
/// the editor; the X or a swipe up dismisses it.
public struct ProfilePromptCard: View {
  let onOpen: () -> Void
  let onDismiss: () -> Void
  @State private var dragOffset: CGFloat = 0
  @Environment(\.theme) private var theme

  public init(onOpen: @escaping () -> Void, onDismiss: @escaping () -> Void) {
    self.onOpen = onOpen
    self.onDismiss = onDismiss
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(Strings.profilePromptTitle)
          .font(theme.typography.font(size: 16, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
        Spacer()
        Button(action: onDismiss) {
          Label(Strings.actionClose, systemImage: "xmark").labelStyle(.iconOnly)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(theme.palette.textTertiary)
        }
        .buttonStyle(ScaleButtonStyle())
      }
      Text(Strings.profilePromptSubtitle)
        .font(theme.typography.font(size: 13, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
        .lineSpacing(2)
      Button(action: onOpen) {
        Text(Strings.profilePromptAction)
          .font(theme.typography.font(size: 14, weight: .semibold))
          .foregroundStyle(theme.palette.accent)
      }
      .buttonStyle(.plain)
      .padding(.top, 4)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    .offset(y: dragOffset)
    .opacity(1 - abs(dragOffset) / 120)
    .gesture(
      DragGesture()
        .onChanged { value in
          if value.translation.height < 0 { dragOffset = value.translation.height }
        }
        .onEnded { value in
          if value.translation.height < -80 {
            withAnimation(.easeOut(duration: 0.2)) { dragOffset = -200 }
            onDismiss()
          } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dragOffset = 0 }
          }
        })
  }
}
