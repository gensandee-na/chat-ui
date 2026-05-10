import Foundation

/// Path constants for the v2 REST API. All paths are relative to
/// `AppConfig.baseURL` (e.g. `https://huggingface.co/chat`).
enum Endpoints {
    static let conversations = "/api/v2/conversations"
    static func conversation(_ id: String) -> String { "/api/v2/conversations/\(id)" }
    static let models = "/api/v2/models"
    static let user = "/api/v2/user"
    static let userSettings = "/api/v2/user/settings"
    static let publicConfig = "/api/v2/public-config"
    static let featureFlags = "/api/v2/feature-flags"

    static func share(_ conversationId: String) -> String {
        "/conversation/\(conversationId)/share"
    }
    static func stopGenerating(_ conversationId: String) -> String {
        "/conversation/\(conversationId)/stop-generating"
    }
    static let logout = "/logout"
}
