import Foundation

struct UserInfo: Decodable, Hashable {
    let id: String
    let username: String?
    let avatarUrl: String?
    let email: String?
    let isAdmin: Bool
    let isEarlyAccess: Bool
}
