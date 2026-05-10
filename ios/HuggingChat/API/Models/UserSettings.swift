import Foundation

struct UserSettings: Codable, Hashable {
    var activeModel: String
    var streamingMode: String?  // "raw" | "smooth"
    var directPaste: Bool?
    var hapticsEnabled: Bool?
    var customPrompts: [String: String]?
    var customPromptsEnabled: [String: Bool]?
    var multimodalOverrides: [String: Bool]?
    var toolsOverrides: [String: Bool]?
    var hidePromptExamples: [String: Bool]?
    var providerOverrides: [String: String]?
    var reasoningEffortOverrides: [String: String]?
    var reasoningOverrides: [String: Bool]?
    var billingOrganization: String?
}
