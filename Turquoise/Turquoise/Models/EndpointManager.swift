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
                
                // 更新或创建规则集
                for networkRuleSet in networkRuleSets {
                    let fetchDescriptor = FetchDescriptor<RuleSet>(
                        predicate: #Predicate<RuleSet> { $0.uuid == networkRuleSet.uuid }
                    )
                    
                    if let existingRuleSet = try modelContext?.fetch(fetchDescriptor).first {
                        existingRuleSet.name = networkRuleSet.name
                        existingRuleSet.ruleDescription = networkRuleSet.description
                        existingRuleSet.recordCount = networkRuleSet.recordCount
                        existingRuleSet.lastRecordAt = networkRuleSet.lastRecordAt
                    } else {
                        let newRuleSet = RuleSet(
                            uuid: networkRuleSet.uuid,
                            name: networkRuleSet.name,
                            description: networkRuleSet.description,
                            recordCount: networkRuleSet.recordCount,
                            lastRecordAt: networkRuleSet.lastRecordAt,
                            isSubscribed: false,
                            endpointID: endpoint.id
                        )
                        modelContext?.insert(newRuleSet)
                    }
                }
                
                try modelContext?.save()
                loadingState = .loaded
                
            } catch let error as NetworkError {
                loadingState = .error(error.localizedDescription)
            } catch {
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