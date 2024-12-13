import Foundation

struct PortalRecordResponse: Codable {
    let success: Bool
    let data: [PortalRecord]
}

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
    
    static var preview: PortalRecord {
        PortalRecord(
            id: 1,
            portalName: "Test Portal",
            portalAddress: "Test Address",
            latitude: 22.5924,
            longitude: 113.8976,
            agentName: "TestAgent",
            timestamp: Date(),
            meetRuleSets: ["test-uuid"]
        )
    }
} 