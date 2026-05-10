import Foundation
import UIKit
import WebKit

/// Routes decoded bridge messages to the appropriate native subsystems.
@MainActor
final class BridgeDispatcher {
    weak var webView: WKWebView?
    let router: AppRouter
    let auth: AuthState
    let filePicker: FilePickerCoordinator
    private let haptics = HapticsService()

    init(router: AppRouter, auth: AuthState, filePicker: FilePickerCoordinator) {
        self.router = router
        self.auth = auth
        self.filePicker = filePicker
    }

    func handle(_ message: BridgeMessage) {
        switch message {
        case .nativeShare(let conversationId):
            router.presentedShareConversationId = conversationId

        case .nativeAttachFile(let accept, let multiple, let requestId):
            Task { @MainActor in
                let files = (try? await filePicker.pickFiles(accept: accept, multiple: multiple)) ?? []
                guard let webView else { return }
                let payload = files.map {
                    [
                        "name": $0.name,
                        "mime": $0.mime,
                        "base64": $0.base64,
                    ]
                }
                let js = BridgeJS.call("attachFiles", args: [payload, requestId])
                _ = try? await webView.evaluateJavaScript(js)
            }

        case .nativeOpenSettings(let tab):
            router.presentedSettingsTab = tab
            router.selectedTab = .settings

        case .nativeOpenModelPicker:
            router.presentedModelPicker = true

        case .nativeOpenLogin:
            Task { @MainActor in
                let coordinator = LoginCoordinator()
                do {
                    try await coordinator.start()
                    await auth.refresh()
                    webView?.reload()
                } catch {
                    NSLog("[hfchat] login from bridge failed: \(error)")
                }
            }

        case .nativeHaptic(let style):
            haptics.fire(style)

        case .webDidLoad(let conversationId):
            if router.currentConversationId != conversationId {
                router.currentConversationId = conversationId
            }

        case .webDidUpdateTitle(let conversationId, let title):
            NotificationCenter.default.post(
                name: .hfchatTitleUpdated,
                object: nil,
                userInfo: ["conversationId": conversationId, "title": title]
            )

        case .webDidStartGeneration(let conversationId):
            NotificationCenter.default.post(
                name: .hfchatGenerationStateChanged,
                object: nil,
                userInfo: ["conversationId": conversationId, "isGenerating": true]
            )

        case .webDidEndGeneration(let conversationId, let interrupted):
            NotificationCenter.default.post(
                name: .hfchatGenerationStateChanged,
                object: nil,
                userInfo: [
                    "conversationId": conversationId,
                    "isGenerating": false,
                    "interrupted": interrupted,
                ]
            )

        case .webRequestNewConversation:
            router.newConversation()

        case .webError(let message, let statusCode):
            NSLog("[hfchat] web error \(statusCode ?? -1): \(message)")
        }
    }
}

extension Notification.Name {
    static let hfchatTitleUpdated = Notification.Name("HuggingChat.titleUpdated")
    static let hfchatGenerationStateChanged = Notification.Name(
        "HuggingChat.generationStateChanged")
}
