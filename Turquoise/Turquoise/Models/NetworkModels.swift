import Foundation

struct NetworkRuleSet: Codable {
    let uuid: String
    let name: String
    let description: String
    let recordCount: Int
    let lastRecordAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case description
        case recordCount = "record_count"
        case lastRecordAt = "last_record_at"
    }
}

struct RuleSetListResponse: Codable {
    let success: Bool
    let data: [NetworkRuleSet]
} 