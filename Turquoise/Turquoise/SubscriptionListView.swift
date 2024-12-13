import SwiftUI

struct SubscriptionListView: View {
    @StateObject private var endpointManager = EndpointManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(endpointManager.endpoints) { endpoint in
                    NavigationLink(destination: RuleSetListView(endpoint: endpoint)) {
                        VStack(alignment: .leading) {
                            Text(endpoint.name)
                                .font(.headline)
                            Text(endpoint.url)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Subscriptions")
        }
    }
}

#Preview {
    SubscriptionListView()
} 