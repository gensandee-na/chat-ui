import Foundation
import Observation
import WebKit

/// Tracks whether the user has a valid session cookie. Single source of truth
/// for "are we logged in" — read by `RootView`, mutated by `LoginCoordinator`
/// after a successful sign-in and on explicit sign-out.
@Observable
final class AuthState {
    var isLoggedIn: Bool = false

    /// Re-read the session cookie from `WKWebsiteDataStore.default()` and
    /// update `isLoggedIn`. Call on launch and after the login flow completes.
    @MainActor
    func refresh() async {
        let store = WKWebsiteDataStore.default().httpCookieStore
        let cookies = await store.allCookies()
        let session = cookies.first { cookie in
            cookie.name == AppConfig.sessionCookieName
                && cookie.domain.contains("huggingface.co")
        }
        if let session {
            isLoggedIn = session.expiresDate.map { $0 > .now } ?? true
        } else {
            isLoggedIn = false
        }
    }

    @MainActor
    func signOut() async {
        await CookieJar.clearAll()
        isLoggedIn = false
    }
}
