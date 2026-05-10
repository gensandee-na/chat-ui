import Foundation
import WebKit

/// Generates the WKUserScript that installs the inbound side of the bridge.
///
/// The web bundle (see `src/lib/native/bridge.ts`) reads its `isNative` flag by
/// checking `window.webkit.messageHandlers.hfchat`. That handler is registered
/// by `WebViewConfiguration` — this script is only responsible for declaring
/// the `window.__hfchatBridge` stub the web side overwrites in
/// `installInboundBridge`. We pre-install a tiny no-op so that any race-y
/// access from the page (before `onMount` runs) doesn't throw.
enum BridgeJS {
    static let bootstrap = """
        (function () {
          if (window.__hfchatBridge) return;
          var noop = function () {};
          window.__hfchatBridge = {
            attachFiles: noop,
            setActiveModel: noop,
            navigate: noop,
            theme: noop,
            stopGeneration: noop,
            injectAuthCookie: noop,
          };
        })();
        """

    static func userScript() -> WKUserScript {
        WKUserScript(
            source: bootstrap,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }

    /// Build a JS expression that calls a method on `window.__hfchatBridge`
    /// with JSON-encoded arguments. Returns a string ready for
    /// `evaluateJavaScript`.
    static func call(_ method: String, args: [Any]) -> String {
        let payload = (try? JSONSerialization.data(withJSONObject: args)) ?? Data("[]".utf8)
        let json = String(data: payload, encoding: .utf8) ?? "[]"
        return "window.__hfchatBridge && window.__hfchatBridge.\(method).apply(null, \(json));"
    }
}
