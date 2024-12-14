import Foundation
import SwiftData

@Model
final class Endpoint {
    var id: UUID
    var name: String
    var url: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var ruleSets: [RuleSet]
    
    init(name: String, url: String) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.createdAt = Date()
        self.ruleSets = []
    }
    
    static var preview: Endpoint {
        Endpoint(name: "Test Endpoint", url: "https://test.com")
    }
}

@Model
final class RuleSet {
    var uuid: String
    var name: String
    var ruleDescription: String
    var recordCount: Int
    var lastRecordAt: Date?
    var isSubscribed: Bool
    var createdAt: Date
    var endpointID: UUID
    
    init(uuid: String, name: String, description: String, recordCount: Int = 0, lastRecordAt: Date? = nil, isSubscribed: Bool = false, endpointID: UUID) {
        self.uuid = uuid
        self.name = name
        self.ruleDescription = description
        self.recordCount = recordCount
        self.lastRecordAt = lastRecordAt
        self.isSubscribed = isSubscribed
        self.createdAt = Date()
        self.endpointID = endpointID
    }
    
    static var preview: RuleSet {
        RuleSet(
            uuid: "test-uuid",
            name: "Test Rule",
            description: "Test Description",
            recordCount: 5,
            lastRecordAt: Date(),
            isSubscribed: true,
            endpointID: UUID()
        )
    }
} 