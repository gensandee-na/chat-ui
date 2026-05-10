import Foundation

/// Thin REST client over `URLSession`. Cookies are attached automatically via
/// the shared cookie storage — `ASWebAuthenticationSession` writes the
/// `hf-chat` cookie there during sign-in, and `URLSession` reads it from the
/// same jar. No manual header plumbing needed.
@MainActor
final class HFClient {
    static let shared = HFClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = .shared
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        self.session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func listConversations(page: Int = 0) async throws -> ConversationListResponse {
        try await get(Endpoints.conversations, query: [URLQueryItem(name: "p", value: "\(page)")])
    }

    func createConversation(_ body: CreateConversationRequest) async throws
        -> CreateConversationResponse
    {
        try await post(Endpoints.conversations, body: body)
    }

    func deleteConversation(id: String) async throws {
        _ = try await delete(Endpoints.conversation(id))
    }

    func patchConversation(id: String, body: PatchConversationRequest) async throws {
        _ = try await patch(Endpoints.conversation(id), body: body)
    }

    func listModels() async throws -> [ModelInfo] {
        try await get(Endpoints.models)
    }

    func currentUser() async throws -> UserInfo? {
        try await get(Endpoints.user)
    }

    func userSettings() async throws -> UserSettings {
        try await get(Endpoints.userSettings)
    }

    func updateUserSettings(_ patch: UserSettings) async throws -> UserSettings {
        try await post(Endpoints.userSettings, body: patch)
    }

    func share(conversationId: String) async throws -> String {
        struct ShareResponse: Decodable { let url: String }
        let resp: ShareResponse = try await post(
            Endpoints.share(conversationId), body: EmptyBody())
        return resp.url
    }

    func stopGeneration(conversationId: String) async throws {
        _ = try await post(Endpoints.stopGenerating(conversationId), body: EmptyBody())
            as EmptyDecodable
    }

    func signOut() async throws {
        _ = try await post(Endpoints.logout, body: EmptyBody()) as EmptyDecodable
    }

    // MARK: - HTTP plumbing

    private struct EmptyBody: Encodable {}
    private struct EmptyDecodable: Decodable {}

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var url = AppConfig.apiURL(path)
        if !query.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = query
            url = components.url!
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await send(request)
    }

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws
        -> Response
    {
        var request = URLRequest(url: AppConfig.apiURL(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func patch<Body: Encodable>(_ path: String, body: Body) async throws -> Data {
        var request = URLRequest(url: AppConfig.apiURL(path))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await sendRaw(request)
    }

    private func delete(_ path: String) async throws -> Data {
        var request = URLRequest(url: AppConfig.apiURL(path))
        request.httpMethod = "DELETE"
        return try await sendRaw(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await sendRaw(request)
        if data.isEmpty, T.self == EmptyDecodable.self {
            // swiftlint:disable:next force_cast
            return EmptyDecodable() as! T
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func sendRaw(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return data }
            switch http.statusCode {
            case 200..<300:
                return data
            case 401, 403:
                throw APIError.unauthorized
            default:
                let body = String(data: data, encoding: .utf8)
                throw APIError.http(http.statusCode, body)
            }
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.transport(error)
        }
    }
}
