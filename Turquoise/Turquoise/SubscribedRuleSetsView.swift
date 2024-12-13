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

#Preview {
    SubscribedRuleSetsView()
} 