import Foundation

struct Endpoint: Codable, Identifiable {
    let id: UUID
    var name: String
    var url: String
    var createdAt: Date
    
    init(name: String, url: String) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.createdAt = Date()
    }
}

struct RuleSet: Codable, Identifiable {
    let uuid: String
    var name: String
    var description: String
    var recordCount: Int
    var lastRecordAt: Date?
    var isSubscribed: Bool
    
    var id: String { uuid }
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case description
        case recordCount = "record_count"
        case lastRecordAt = "last_record_at"
        case isSubscribed
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        recordCount = try container.decode(Int.self, forKey: .recordCount)
        lastRecordAt = try container.decodeIfPresent(Date.self, forKey: .lastRecordAt)
        isSubscribed = false  // 默认值，因为这是客户端状态
    }
}

enum LoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}

class EndpointManager: ObservableObject {
    static let shared = EndpointManager()
    
    @Published private(set) var endpoints: [Endpoint] = []
    @Published private(set) var subscriptions: [RuleSet] = []
    @Published private(set) var loadingState: LoadingState = .idle
    
    private let endpointsKey = "savedEndpoints"
    private let subscriptionsKey = "savedSubscriptions"
    
    init() {
        loadEndpoints()
        loadSubscriptions()
    }
    
    // MARK: - Endpoints Management
    func addEndpoint(name: String, url: String) {
        let endpoint = Endpoint(name: name, url: url)
        endpoints.append(endpoint)
        saveEndpoints()
    }
    
    func removeEndpoint(at offsets: IndexSet) {
        endpoints.remove(atOffsets: offsets)
        saveEndpoints()
    }
    
    private func loadEndpoints() {
        if let data = UserDefaults.standard.data(forKey: endpointsKey),
           let savedEndpoints = try? JSONDecoder().decode([Endpoint].self, from: data) {
            endpoints = savedEndpoints
        }
    }
    
    private func saveEndpoints() {
        if let encoded = try? JSONEncoder().encode(endpoints) {
            UserDefaults.standard.set(encoded, forKey: endpointsKey)
        }
    }
    
    // MARK: - Subscriptions Management
    func updateSubscription(_ ruleSet: RuleSet) {
        if let index = subscriptions.firstIndex(where: { $0.uuid == ruleSet.uuid }) {
            subscriptions[index] = ruleSet
        } else {
            subscriptions.append(ruleSet)
        }
        saveSubscriptions()
    }
    
    func removeSubscription(_ uuid: String) {
        subscriptions.removeAll { $0.uuid == uuid }
        saveSubscriptions()
    }
    
    private func loadSubscriptions() {
        if let data = UserDefaults.standard.data(forKey: subscriptionsKey),
           let savedSubscriptions = try? JSONDecoder().decode([RuleSet].self, from: data) {
            subscriptions = savedSubscriptions
        }
    }
    
    private func saveSubscriptions() {
        if let encoded = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(encoded, forKey: subscriptionsKey)
        }
    }
    
    func loadRuleSets(for endpoint: Endpoint) {
        Task { @MainActor in
            loadingState = .loading
            do {
                let ruleSets = try await NetworkService.shared.fetchRuleSets(from: endpoint)
                
                // 保留其他端点的订阅，只更新当前端点的规则集
                var newSubscriptions = subscriptions.filter { subscription in
                    !ruleSets.contains { $0.uuid == subscription.uuid }
                }
                
                // 处理当前端点的规则集
                let currentEndpointRuleSets = ruleSets.map { ruleSet in
                    var updatedRuleSet = ruleSet
                    // 如果之前订阅过，保持订阅状态
                    if let existingRuleSet = subscriptions.first(where: { $0.uuid == ruleSet.uuid }) {
                        updatedRuleSet.isSubscribed = existingRuleSet.isSubscribed
                    } else {
                        updatedRuleSet.isSubscribed = false
                    }
                    return updatedRuleSet
                }
                
                // 合并其他端点的订阅和当前端点的规则集
                newSubscriptions.append(contentsOf: currentEndpointRuleSets)
                
                // 更新状态
                self.subscriptions = newSubscriptions
                self.loadingState = .loaded
                
                // 保存到本地存储
                saveSubscriptions()
            } catch let error as NetworkError {
                switch error {
                case .decodingError:
                    self.loadingState = .error("Invalid API response. Please check the endpoint URL.")
                case .invalidURL:
                    self.loadingState = .error("Invalid URL. Please check the endpoint configuration.")
                case .invalidResponse:
                    self.loadingState = .error("Server returned an invalid response. Please try again later.")
                case .serverError(let message):
                    self.loadingState = .error("Server error: \(message)")
                }
            } catch {
                self.loadingState = .error("Failed to load rule sets: \(error.localizedDescription)")
            }
        }
    }
    
    func retryLoadRuleSets(for endpoint: Endpoint) {
        loadingState = .idle
        loadRuleSets(for: endpoint)
    }
} 