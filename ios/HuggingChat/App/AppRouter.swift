import Foundation
import Observation

/// Cross-tab navigation state. Native screens (conversation list, model
/// picker, settings) update this; the WebView host reads `currentConversationId`
/// to decide which embed URL to load.
@Observable
final class AppRouter {
    var currentConversationId: String?
    var selectedTab: Tab = .chat
    var presentedSettingsTab: String?
    var presentedShareConversationId: String?
    var presentedModelPicker: Bool = false

    enum Tab: Hashable { case chat, conversations, settings }

    func openConversation(_ id: String) {
        currentConversationId = id
        selectedTab = .chat
    }

    func newConversation() {
        currentConversationId = nil
        selectedTab = .chat
    }
}
