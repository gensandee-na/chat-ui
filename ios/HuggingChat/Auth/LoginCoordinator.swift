import AuthenticationServices
import Foundation
import UIKit

/// Drives the OAuth flow.
///
/// We open `https://huggingface.co/chat/login?next=/chat/login/native-done`
/// inside `ASWebAuthenticationSession`. The provider auth and the
/// `/login/callback` step both happen there, which means the upstream cookie
/// jar (system `HTTPCookieStorage.shared`) receives the final `hf-chat`
/// session cookie. The `native-done` route then issues a
/// `<meta http-equiv=refresh>` that fires `hf-chat://auth-done`, which
/// `ASWebAuthenticationSession` matches against `callbackURLScheme` to invoke
/// the completion handler.
///
/// After completion we copy the session cookie into the WebView's cookie store
/// via `CookieJar.syncSharedToWebView()`.
@MainActor
final class LoginCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func start() async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            let session = ASWebAuthenticationSession(
                url: AppConfig.loginURL(),
                callbackURLScheme: AppConfig.authCallbackScheme
            ) { _, error in
                Task { @MainActor in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    await CookieJar.syncSharedToWebView()
                    continuation.resume()
                }
            }
            session.presentationContextProvider = self
            // Persist cookies into HTTPCookieStorage.shared so we can copy them
            // out after the flow.
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            if !session.start() {
                continuation.resume(
                    throwing: NSError(
                        domain: "HuggingChat", code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Failed to start authentication session"
                        ]))
            }
        }
    }

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
