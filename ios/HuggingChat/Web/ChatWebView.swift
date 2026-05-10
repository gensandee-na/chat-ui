import SwiftUI
import WebKit

/// SwiftUI wrapper around the embedded chat WKWebView.
struct ChatWebView: UIViewRepresentable {
    let conversationId: String?

    @Environment(AuthState.self) private var auth
    @Environment(AppRouter.self) private var router

    func makeCoordinator() -> Coordinator {
        Coordinator(router: router, auth: auth)
    }

    @MainActor
    func makeUIView(context: Context) -> WKWebView {
        let dispatcher = context.coordinator.dispatcher
        let handler = BridgeMessageHandler(dispatcher: dispatcher)
        let config = WebViewConfiguration.make(handler: handler)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        dispatcher.webView = webView

        Task { @MainActor in
            await CookieJar.syncSharedToWebView()
            loadCurrent(webView: webView)
        }

        return webView
    }

    @MainActor
    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedConversationId != conversationId {
            context.coordinator.lastLoadedConversationId = conversationId
            loadCurrent(webView: webView)
        }
    }

    @MainActor
    private func loadCurrent(webView: WKWebView) {
        let url: URL
        if let id = conversationId {
            url = AppConfig.embedConversationURL(id: id, hideShare: true)
        } else {
            // Fall back to the canonical root, which redirects to a fresh chat.
            url = AppConfig.baseURL
        }
        webView.load(URLRequest(url: url))
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let dispatcher: BridgeDispatcher
        var lastLoadedConversationId: String?

        init(router: AppRouter, auth: AuthState) {
            let filePicker = FilePickerCoordinator()
            self.dispatcher = BridgeDispatcher(router: router, auth: auth, filePicker: filePicker)
            super.init()
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Intercept top-level navigations to /login — those are OAuth
            // redirects that the WebView shouldn't follow itself; the native
            // login coordinator handles them via ASWebAuthenticationSession.
            if let url = navigationAction.request.url,
                url.path.hasSuffix("/login") || url.path.contains("/login?")
            {
                decisionHandler(.cancel)
                Task { @MainActor in
                    let coordinator = LoginCoordinator()
                    try? await coordinator.start()
                    await dispatcher.auth.refresh()
                    webView.reload()
                }
                return
            }
            decisionHandler(.allow)
        }
    }
}
