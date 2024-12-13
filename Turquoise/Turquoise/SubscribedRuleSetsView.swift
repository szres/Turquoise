import SwiftUI

struct SubscribedRuleSetsView: View {
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var isLoading = false
    
    var subscribedRuleSets: [RuleSet] {
        endpointManager.subscriptions.filter { $0.isSubscribed }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if subscribedRuleSets.isEmpty {
                    VStack {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Subscribed Rules")
                            .font(.headline)
                        Text("Subscribe to rules to receive notifications")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(subscribedRuleSets) { ruleSet in
                            NavigationLink(destination: RuleSetDetailView(ruleSet: ruleSet)) {
                                RuleSetRow(ruleSet: ruleSet)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Subscribed Rules")
            .onAppear {
                refreshSubscriptions()
            }
            .refreshable {
                await refreshSubscriptions()
            }
        }
    }
    
    private func refreshSubscriptions() {
        Task {
            isLoading = true
            await endpointManager.syncSubscriptions()
            isLoading = false
        }
    }
}

struct RuleSetDetailView: View {
    let ruleSet: RuleSet
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var records: [PortalRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                VStack {
                    Text("Error loading records")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        loadRecords()
                    }
                    .buttonStyle(.bordered)
                }
            } else if records.isEmpty {
                Text("No records found")
                    .foregroundColor(.secondary)
            } else {
                List(records) { record in
                    RecordRow(record: record)
                }
            }
        }
        .navigationTitle(ruleSet.name)
        .onAppear {
            loadRecords()
        }
    }
    
    private func loadRecords() {
        guard let endpoint = endpointManager.endpoints.first else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let newRecords = try await NetworkService.shared.fetchRuleSetRecords(
                    endpoint: endpoint,
                    ruleSetId: ruleSet.uuid
                )
                await MainActor.run {
                    records = newRecords
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SubscribedRuleSetsView()
} 