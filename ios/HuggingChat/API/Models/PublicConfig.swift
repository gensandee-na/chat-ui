import Foundation

struct PublicConfig: Decodable {
    let raw: [String: AnyCodableValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try container.decode([String: AnyCodableValue].self)
    }

    func string(_ key: String) -> String? { raw[key]?.stringValue }
    func bool(_ key: String) -> Bool? { raw[key]?.boolValue }
}

struct FeatureFlags: Decodable {
    let raw: [String: AnyCodableValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try container.decode([String: AnyCodableValue].self)
    }

    func bool(_ key: String) -> Bool? { raw[key]?.boolValue }
}

/// Permissive container so we don't pin every public-config / feature-flag
/// key into a Swift type.
enum AnyCodableValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case other

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .null
        } else if let v = try? c.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? c.decode(Int.self) {
            self = .int(v)
        } else if let v = try? c.decode(Double.self) {
            self = .double(v)
        } else if let v = try? c.decode(String.self) {
            self = .string(v)
        } else {
            self = .other
        }
    }

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }
    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }
}
