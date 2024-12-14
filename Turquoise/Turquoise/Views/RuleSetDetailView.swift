import SwiftUI
import SwiftData

struct RuleSetDetailView: View {
    let ruleSet: RuleSet
    @Environment(\.modelContext) private var modelContext
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var records: [PortalRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @Query private var endpoints: [Endpoint]
    
    private var endpoint: Endpoint? {
        endpoints.first { $0.id == ruleSet.endpointID }
    }
    
    init(ruleSet: RuleSet) {
        self.ruleSet = ruleSet
        self._endpoints = Query()
    }
    
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
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Records Found")
                        .font(.headline)
                    Text("This rule set hasn't matched any portals yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    Section {
                        ForEach(records) { record in
                            RecordRow(record: record)
                        }
                    } header: {
                        Text("\(records.count) Records")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle(ruleSet.name)
        .navigationBarTitleDisplayMode(.inline)
        #if os(macOS)
        .frame(alignment: .leading)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    loadRecords()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            loadRecords()
        }
    }
    
    private func loadRecords() {
        guard let endpoint = endpoint else {
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

#Preview {
    NavigationView {
        RuleSetDetailView(ruleSet: .preview)
    }
} 