import Foundation
import WebKit

/// `WKScriptMessageHandler` that decodes JSON payloads from the WebView and
/// forwards them to the dispatcher. The handler is registered under the name
/// `hfchat`, which matches `window.webkit.messageHandlers.hfchat` on the JS
/// side.
final class BridgeMessageHandler: NSObject, WKScriptMessageHandler {
    private let dispatcher: BridgeDispatcher

    init(dispatcher: BridgeDispatcher) {
        self.dispatcher = dispatcher
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "hfchat" else { return }
        guard JSONSerialization.isValidJSONObject(message.body) else {
            NSLog("[hfchat] message body is not JSON-serializable: \(message.body)")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: message.body)
            let decoded = try JSONDecoder().decode(BridgeMessage.self, from: data)
            Task { @MainActor in dispatcher.handle(decoded) }
        } catch {
            NSLog("[hfchat] failed to decode bridge message: \(error)")
        }
    }
}
