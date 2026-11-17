import SwiftUI

/// The Learn tab without a page (the web page itself can't be rendered off
/// screen), for previews and render tests. Internal.
struct LearnContentGallery: View {
  var body: some View {
    LearnContent(url: nil)
      .frame(height: 600)
  }
}

#Preview("Learn, no page") {
  LearnContent(url: nil)
}

#Preview("Learn") {
  LearnContent(url: URL(string: "https://www.apple.com"))
}
