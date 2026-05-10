import Foundation

/// Item returned by `GET /api/v2/conversations`. Mirrors the shape used by
/// `+layout.ts` on the SvelteKit side.
struct ConversationListItem: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let model: String?
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, model, updatedAt
    }
}

struct ConversationListResponse: Decodable {
    let conversations: [ConversationListItem]
    let hasMore: Bool
}

struct CreateConversationRequest: Encodable {
    let title: String?
    let model: String?
}

struct CreateConversationResponse: Decodable {
    let conversationId: String
}

struct PatchConversationRequest: Encodable {
    let title: String?
    let model: String?
}
