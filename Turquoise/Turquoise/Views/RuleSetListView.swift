import SwiftUI
import SwiftData

struct RuleSetListView: View {
    let endpoint: Endpoint
    @Environment(\.modelContext) private var modelContext
    @Query private var ruleSets: [RuleSet]
    @StateObject private var endpointManager = EndpointManager.shared
    
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
        let endpointID = endpoint.id
        print("🔍 Querying rulesets for endpoint: \(endpoint.name)")
        self._ruleSets = Query(
            filter: #Predicate<RuleSet> { ruleSet in
                ruleSet.endpointID == endpointID
            },
            sort: [SortDescriptor(\RuleSet.name)]
        )
    }
    
    var body: some View {
        Group {
            switch endpointManager.loadingState {
            case .idle, .loading:
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            case .loaded:
                if ruleSets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Rule Sets Available")
                            .font(.headline)
                        Text("Pull to refresh or try again later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(ruleSets) { ruleSet in
                            RuleSetSubscribeRow(ruleSet: ruleSet)
                        }
                    }
                }
            case .error(let message):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(message)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        endpointManager.loadRuleSets(for: endpoint)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle(endpoint.name)
        .refreshable {
            endpointManager.loadRuleSets(for: endpoint)
        }
        .onAppear {
            endpointManager.setModelContext(modelContext)
            endpointManager.loadRuleSets(for: endpoint)
        }
    }
}

#Preview {
    NavigationView {
        RuleSetListView(endpoint: .preview)
    }
} 