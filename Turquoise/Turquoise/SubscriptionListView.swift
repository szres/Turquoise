import SwiftUI
import SwiftData

struct SubscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Endpoint.createdAt) private var endpoints: [Endpoint]
    @StateObject private var endpointManager = EndpointManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(endpoints) { endpoint in
                    NavigationLink(destination: RuleSetListView(endpoint: endpoint)) {
                        VStack(alignment: .leading) {
                            Text(endpoint.name)
                                .font(.headline)
                            Text(endpoint.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Subscribed")
            .refreshable {
                // 可以添加刷新逻辑
            }
        }
        .onAppear {
            endpointManager.setModelContext(modelContext)
        }
    }
}

#Preview {
    SubscriptionListView()
        .modelContainer(for: [Endpoint.self, RuleSet.self])
} 