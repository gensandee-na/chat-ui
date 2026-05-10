import Foundation

/// Static configuration for the HuggingChat iOS app.
///
/// Hardcoded for HuggingChat (`huggingface.co/chat`). Self-hosted instance
/// support is intentionally deferred — see the v1 plan.
enum AppConfig {
    /// Origin of the chat-ui server. All API calls and the embedded WebView
    /// load relative to this base.
    static let baseURL = URL(string: "https://huggingface.co/chat")!

    /// Custom URL scheme that the `/login/native-done` route bounces to in
    /// order to fire the `ASWebAuthenticationSession` completion handler.
    static let authCallbackScheme = "hf-chat"
    static let authCallbackHost = "auth-done"

    /// Name of the session cookie set by the chat-ui server (`COOKIE_NAME`
    /// env, default `hf-chat`).
    static let sessionCookieName = "hf-chat"

    /// User-Agent suffix appended to WKWebView and URLSession requests so the
    /// server can recognize native traffic if needed (analytics, banner
    /// suppression, etc.).
    static let userAgentSuffix = "HuggingChatiOS/1.0"

    /// Build the URL for the embed conversation page. Matches the
    /// `embed/conversation/[id]` route on the SvelteKit side, which uses an
    /// `@`-reset layout so it inherits no global navigation chrome.
    static func embedConversationURL(id: String, hideShare: Bool = true, theme: String? = nil)
        -> URL
    {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path =
            (components.path.isEmpty ? "" : components.path) + "/embed/conversation/\(id)"
        var items: [URLQueryItem] = []
        if hideShare { items.append(URLQueryItem(name: "hideShare", value: "1")) }
        if let theme { items.append(URLQueryItem(name: "theme", value: theme)) }
        items.append(URLQueryItem(name: "hapticsBridge", value: "1"))
        components.queryItems = items
        return components.url!
    }

    /// Build the URL for the login flow targeting the native-done bounce.
    static func loginURL() -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path += "/login"
        components.queryItems = [URLQueryItem(name: "next", value: "/chat/login/native-done")]
        return components.url!
    }

    static func apiURL(_ path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }
}
