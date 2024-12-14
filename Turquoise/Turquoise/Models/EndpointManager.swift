import Foundation
import SwiftData
import Combine

class EndpointManager: ObservableObject {
    static let shared = EndpointManager()
    
    var modelContext: ModelContext?
    @Published var loadingState: LoadingState = .idle
    @Published private(set) var endpoints: [Endpoint] = []
    
    private init() {
        loadEndpoints()
    }
    
    private func loadEndpoints() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Endpoint>(sortBy: [SortDescriptor(\.createdAt)])
        endpoints = (try? context.fetch(descriptor)) ?? []
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Endpoints Management
    func addEndpoint(name: String, url: String) {
        guard let context = modelContext else { return }
        let endpoint = Endpoint(name: name, url: url)
        context.insert(endpoint)
        try? context.save()
        
        // 重新加载 endpoints
        loadEndpoints()
    }
    
    func removeEndpoint(_ endpoint: Endpoint) {
        guard let context = modelContext else { return }
        context.delete(endpoint)
        try? context.save()
    }
    
    func updateEndpoint(_ endpoint: Endpoint, name: String, url: String) {
        endpoint.name = name
        endpoint.url = url
        try? modelContext?.save()
    }
    
    // MARK: - RuleSets Management
    func updateRuleSet(_ ruleSet: RuleSet) {
        try? modelContext?.save()
    }
    
    func loadRuleSets(for endpoint: Endpoint) {
        Task { @MainActor in
            loadingState = .loading
            do {
                let networkRuleSets = try await NetworkService.shared.fetchRuleSets(from: endpoint)
                print("📱 Received \(networkRuleSets.count) rulesets")
                
                // 更新或创建规则集
                for networkRuleSet in networkRuleSets {
                    let fetchDescriptor = FetchDescriptor<RuleSet>(
                        predicate: #Predicate<RuleSet> { $0.uuid == networkRuleSet.uuid }
                    )
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    let lastRecordDate = networkRuleSet.lastRecordAt.flatMap { dateFormatter.date(from: $0) }
                    
                    if let existingRuleSet = try modelContext?.fetch(fetchDescriptor).first {
                        print("📝 Updating ruleset: \(networkRuleSet.name) with endpointID: \(endpoint.id)")
                        existingRuleSet.name = networkRuleSet.name
                        existingRuleSet.ruleDescription = networkRuleSet.description
                        existingRuleSet.recordCount = networkRuleSet.recordCount
                        existingRuleSet.lastRecordAt = lastRecordDate
                        existingRuleSet.endpointID = endpoint.id
                    } else {
                        print("➕ Creating new ruleset: \(networkRuleSet.name) with endpointID: \(endpoint.id)")
                        let newRuleSet = RuleSet(
                            uuid: networkRuleSet.uuid,
                            name: networkRuleSet.name,
                            description: networkRuleSet.description,
                            recordCount: networkRuleSet.recordCount,
                            lastRecordAt: lastRecordDate,
                            isSubscribed: false,
                            endpointID: endpoint.id
                        )
                        modelContext?.insert(newRuleSet)
                    }
                }
                
                try modelContext?.save()
                print("💾 Saved all rulesets")
                loadingState = .loaded
                
            } catch let error as NetworkError {
                print("❌ Network error: \(error.localizedDescription)")
                loadingState = .error(error.localizedDescription)
            } catch {
                print("❌ Other error: \(error.localizedDescription)")
                loadingState = .error("Failed to load rule sets: \(error.localizedDescription)")
            }
        }
    }
    
    func syncSubscriptions() async {
        do {
            let topics = try await SubscriptionService.shared.fetchSubscribedTopics()
            
            await MainActor.run {
                guard let context = modelContext else { return }
                let fetchDescriptor = FetchDescriptor<RuleSet>()
                if let ruleSets = try? context.fetch(fetchDescriptor) {
                    for ruleSet in ruleSets {
                        ruleSet.isSubscribed = topics.contains(ruleSet.uuid)
                    }
                    try? context.save()
                }
            }
        } catch {
            print("Failed to sync subscriptions: \(error)")
        }
    }
} 