import Foundation
import SwiftData

@Model
final class EndpointModel {
    var id: UUID
    var name: String
    var url: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var ruleSets: [RuleSetModel]
    
    init(name: String, url: String) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.createdAt = Date()
        self.ruleSets = []
    }
}

@Model
final class RuleSetModel {
    var uuid: String
    var name: String
    var ruleDescription: String
    var recordCount: Int
    var lastRecordAt: Date?
    var createdAt: Date
    var isSubscribed: Bool
    
    init(uuid: String, name: String, description: String, recordCount: Int = 0) {
        self.uuid = uuid
        self.name = name
        self.ruleDescription = description
        self.recordCount = recordCount
        self.createdAt = Date()
        self.isSubscribed = false
    }
}

// 添加新的数据模型
struct PortalRecord: Codable, Identifiable {
    let id: Int
    let portalName: String
    let portalAddress: String
    let latitude: Double
    let longitude: Double
    let agentName: String
    let timestamp: Date
    let meetRuleSets: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case portalName = "portal_name"
        case portalAddress = "portal_address"
        case latitude
        case longitude
        case agentName = "agent_name"
        case timestamp
        case meetRuleSets = "meet_rule_sets"
    }
}

struct PortalRecordResponse: Codable {
    let success: Bool
    let data: [PortalRecord]
} 