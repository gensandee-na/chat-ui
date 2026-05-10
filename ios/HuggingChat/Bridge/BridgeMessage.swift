import Foundation

/// Decoded representation of a single message posted by the WebView's
/// `window.webkit.messageHandlers.hfchat.postMessage(...)` call. Mirrors the
/// `Outbound` union in `src/lib/native/bridge.ts`.
enum BridgeMessage: Decodable {
    case nativeShare(conversationId: String)
    case nativeAttachFile(accept: String, multiple: Bool, requestId: String)
    case nativeOpenSettings(tab: String?)
    case nativeOpenModelPicker(currentModelId: String?)
    case nativeOpenLogin(next: String?)
    case nativeHaptic(style: HapticStyle)
    case webDidLoad(conversationId: String)
    case webDidUpdateTitle(conversationId: String, title: String)
    case webDidStartGeneration(conversationId: String)
    case webDidEndGeneration(conversationId: String, interrupted: Bool)
    case webRequestNewConversation(modelId: String?)
    case webError(message: String, statusCode: Int?)

    enum HapticStyle: String, Decodable {
        case selection, impact, success, error
    }

    private enum CodingKeys: String, CodingKey { case type, args, requestId }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "nativeShare":
            let args = try container.decode(ShareArgs.self, forKey: .args)
            self = .nativeShare(conversationId: args.conversationId)
        case "nativeAttachFile":
            let args = try container.decode(AttachArgs.self, forKey: .args)
            let requestId = try container.decode(String.self, forKey: .requestId)
            self = .nativeAttachFile(
                accept: args.accept, multiple: args.multiple, requestId: requestId)
        case "nativeOpenSettings":
            let args = try container.decode(OpenSettingsArgs.self, forKey: .args)
            self = .nativeOpenSettings(tab: args.tab)
        case "nativeOpenModelPicker":
            let args = try container.decode(OpenModelPickerArgs.self, forKey: .args)
            self = .nativeOpenModelPicker(currentModelId: args.currentModelId)
        case "nativeOpenLogin":
            let args = try container.decode(OpenLoginArgs.self, forKey: .args)
            self = .nativeOpenLogin(next: args.next)
        case "nativeHaptic":
            let args = try container.decode(HapticArgs.self, forKey: .args)
            self = .nativeHaptic(style: args.style)
        case "webDidLoad":
            let args = try container.decode(ConversationIdArgs.self, forKey: .args)
            self = .webDidLoad(conversationId: args.conversationId)
        case "webDidUpdateTitle":
            let args = try container.decode(TitleArgs.self, forKey: .args)
            self = .webDidUpdateTitle(conversationId: args.conversationId, title: args.title)
        case "webDidStartGeneration":
            let args = try container.decode(ConversationIdArgs.self, forKey: .args)
            self = .webDidStartGeneration(conversationId: args.conversationId)
        case "webDidEndGeneration":
            let args = try container.decode(EndGenerationArgs.self, forKey: .args)
            self = .webDidEndGeneration(
                conversationId: args.conversationId, interrupted: args.interrupted)
        case "webRequestNewConversation":
            let args = try container.decode(NewConversationArgs.self, forKey: .args)
            self = .webRequestNewConversation(modelId: args.modelId)
        case "webError":
            let args = try container.decode(ErrorArgs.self, forKey: .args)
            self = .webError(message: args.message, statusCode: args.statusCode)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown bridge message: \(type)")
        }
    }

    private struct ShareArgs: Decodable { let conversationId: String }
    private struct AttachArgs: Decodable {
        let accept: String
        let multiple: Bool
    }
    private struct OpenSettingsArgs: Decodable { let tab: String? }
    private struct OpenModelPickerArgs: Decodable { let currentModelId: String? }
    private struct OpenLoginArgs: Decodable { let next: String? }
    private struct HapticArgs: Decodable { let style: HapticStyle }
    private struct ConversationIdArgs: Decodable { let conversationId: String }
    private struct TitleArgs: Decodable {
        let conversationId: String
        let title: String
    }
    private struct EndGenerationArgs: Decodable {
        let conversationId: String
        let interrupted: Bool
    }
    private struct NewConversationArgs: Decodable { let modelId: String? }
    private struct ErrorArgs: Decodable {
        let message: String
        let statusCode: Int?
    }
}
