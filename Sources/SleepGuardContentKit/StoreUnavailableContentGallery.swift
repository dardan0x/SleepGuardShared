import SwiftUI

/// The store-unavailable screen with and without its update button, for
/// previews and render tests. Internal.
struct StoreUnavailableContentGallery: View {
  var showsUpdate = true

  var body: some View {
    StoreUnavailableContent(onUpdate: showsUpdate ? {} : nil)
      .frame(height: 600)
  }
}

#Preview("Store unavailable") {
  StoreUnavailableContent(onUpdate: {})
}

#Preview("Store unavailable, no update") {
  StoreUnavailableContent(onUpdate: nil)
}
