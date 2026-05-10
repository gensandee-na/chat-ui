import Foundation
import WebKit

/// Cookie sync between the system shared `HTTPCookieStorage` (used by
/// `URLSession` and `ASWebAuthenticationSession`) and the WebView's
/// `WKHTTPCookieStore`. Both stores are isolated by default; we mirror the
/// `hf-chat` session cookie across them so the WebView can hit authenticated
/// endpoints and `HFClient` can attach the cookie to its REST calls.
enum CookieJar {
    /// Copy the chat-ui session cookie from `HTTPCookieStorage.shared` (where
    /// `ASWebAuthenticationSession` writes it) into the WebView's cookie store.
    @MainActor
    static func syncSharedToWebView() async {
        let cookies = HTTPCookieStorage.shared.cookies?.filter { $0.matchesHFChat() } ?? []
        let store = WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            await store.setCookie(cookie)
        }
    }

    /// Copy the WebView's session cookie into `HTTPCookieStorage.shared` so
    /// `URLSession`-backed REST calls in `HFClient` send it automatically.
    /// Used after a fresh sign-in if the user signed in via the WebView itself
    /// (currently unused — kept for future flexibility).
    @MainActor
    static func syncWebViewToShared() async {
        let store = WKWebsiteDataStore.default().httpCookieStore
        let cookies = await store.allCookies()
        for cookie in cookies where cookie.matchesHFChat() {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }

    @MainActor
    static func clearAll() async {
        let store = WKWebsiteDataStore.default().httpCookieStore
        let webCookies = await store.allCookies()
        for cookie in webCookies where cookie.matchesHFChat() {
            await store.deleteCookie(cookie)
        }
        if let sharedCookies = HTTPCookieStorage.shared.cookies {
            for cookie in sharedCookies where cookie.matchesHFChat() {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        let dataStore = WKWebsiteDataStore.default()
        let types: Set<String> = [WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage]
        let records = await dataStore.dataRecords(ofTypes: types)
        let hfRecords = records.filter { $0.displayName.contains("huggingface") }
        await dataStore.removeData(ofTypes: types, for: hfRecords)
    }
}

private extension HTTPCookie {
    func matchesHFChat() -> Bool {
        name == AppConfig.sessionCookieName && domain.contains("huggingface.co")
    }
}
