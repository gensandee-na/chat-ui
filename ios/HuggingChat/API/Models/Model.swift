import Foundation

/// Item returned by `GET /api/v2/models`. The web type is `GETModelsResponse[]`
/// in `src/lib/server/api/types.ts` — this is a permissive subset.
struct ModelInfo: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String?
    let description: String?
    let logoUrl: String?
    let multimodal: Bool?
    let supportsTools: Bool?
    let supportsReasoning: Bool?
    let isRouter: Bool?
    let preprompt: String?
}
