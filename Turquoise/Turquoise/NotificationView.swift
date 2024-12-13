import SwiftUI

struct NotificationView: View {
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
                            RuleSetRecordView(ruleSet: ruleSet)
                        }
                    }
                }
            }
            .navigationTitle("Turquoise")
            .refreshable {
                await refreshSubscriptions()
            }
        }
    }
    
    private func refreshSubscriptions() {
        Task {
            isLoading = true
            do {
                await endpointManager.syncSubscriptions()
            } catch {
                print("Failed to sync subscriptions: \(error)")
            }
            isLoading = false
        }
    }
}

struct RuleSetRecordView: View {
    let ruleSet: RuleSet
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var records: [PortalRecord] = []
    @State private var isExpanded = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ruleSet.name)
                    .font(.headline)
                Spacer()
                Text("\(ruleSet.recordCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isExpanded {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    ForEach(records) { record in
                        RecordRow(record: record)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
            if isExpanded && records.isEmpty {
                loadRecords()
            }
        }
    }
    
    private func loadRecords() {
        guard let endpoint = endpointManager.endpoints.first else {
            errorMessage = "No endpoint configured"
            return
        }
        
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

struct RecordRow: View {
    let record: PortalRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.portalName)
                .font(.subheadline)
            Text(record.portalAddress)
                .font(.caption)
            HStack {
                Text("Agent: \(record.agentName)")
                Spacer()
                Text(record.timestamp.formatted())
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.leading)
        .padding(.vertical, 4)
    }
}

#Preview {
    NotificationView()
} 
