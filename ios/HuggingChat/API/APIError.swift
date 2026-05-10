import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case http(Int, String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "You're not signed in."
        case .http(let status, let body):
            return body.map { "HTTP \(status): \($0)" } ?? "HTTP \(status)"
        case .decoding(let err): return "Decoding error: \(err.localizedDescription)"
        case .transport(let err): return err.localizedDescription
        }
    }
}
