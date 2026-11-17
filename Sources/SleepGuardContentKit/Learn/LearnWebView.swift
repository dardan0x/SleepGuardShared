#if canImport(UIKit)
import SwiftUI
import WebKit

/// The Learn page in a web view. A link marked `data-open-external="true"`
/// opens outside the app (SwiftUI's `openURL`, so Safari for web links);
/// every other link stays in the view. The page loads when the URL changes,
/// not on every update.
struct LearnWebView: UIViewRepresentable {
  let url: URL
  @Environment(\.openURL) private var openURL

  /// The script message an external link sends.
  static let messageName = "openExternal"

  /// Catches clicks on external links before the page navigates.
  static let clickInterceptor = """
  (function() {
    document.addEventListener('click', function(event) {
      var target = event.target;
      while (target && target.tagName !== 'A') { target = target.parentElement; }
      if (!target || target.getAttribute('data-open-external') !== 'true' || !target.href) { return; }
      event.preventDefault();
      event.stopPropagation();
      var handlers = window.webkit && window.webkit.messageHandlers;
      if (handlers && handlers.\(messageName)) { handlers.\(messageName).postMessage(target.href); }
    }, true);
  })();
  """

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.addUserScript(
      WKUserScript(source: Self.clickInterceptor, injectionTime: .atDocumentStart, forMainFrameOnly: false))
    configuration.userContentController.add(context.coordinator, name: Self.messageName)
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.backgroundColor = .clear
    webView.isOpaque = false
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    context.coordinator.openExternal = { openURL($0) }
    guard context.coordinator.loaded != url else { return }
    context.coordinator.loaded = url
    webView.load(URLRequest(url: url))
  }

  static func dismantleUIView(_ webView: WKWebView, coordinator _: Coordinator) {
    webView.configuration.userContentController.removeScriptMessageHandler(forName: messageName)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  @MainActor
  final class Coordinator: NSObject, WKScriptMessageHandler {
    var loaded: URL?
    var openExternal: (URL) -> Void = { _ in }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
      guard message.name == LearnWebView.messageName, let text = message.body as? String,
            let url = URL(string: text) else { return }
      openExternal(url)
    }
  }
}
#endif
