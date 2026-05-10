import Foundation
import WebKit

/// Builds a `WKWebViewConfiguration` shared by all WebView instances. Critical:
/// uses the **default** website data store so cookies persist across launches
/// and are visible to `LoginCoordinator` after sign-in.
@MainActor
enum WebViewConfiguration {
    static func make(handler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.applicationNameForUserAgent = AppConfig.userAgentSuffix

        let userContent = WKUserContentController()
        userContent.add(handler, name: "hfchat")
        userContent.addUserScript(BridgeJS.userScript())
        config.userContentController = userContent

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        return config
    }
}
