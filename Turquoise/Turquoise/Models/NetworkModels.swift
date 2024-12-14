import Foundation

struct Rule: Codable {
    let type: String
    let value: String?
    let points: [Point]?
}

struct Point: Codable {
    let lat: Double
    let lng: Double
}

struct NetworkRuleSet: Codable {
    let uuid: String
    let name: String
    let description: String
    let rules: [Rule]
    let createdAt: String
    let updatedAt: String
    let recordCount: Int
    let lastRecordAt: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, description, rules
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case recordCount = "record_count"
        case lastRecordAt = "last_record_at"
    }
}

struct RuleSetListResponse: Codable {
    let success: Bool
    let data: [NetworkRuleSet]
} 