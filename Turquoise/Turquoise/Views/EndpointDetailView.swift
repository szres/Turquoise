import SwiftUI
import SwiftData

struct EndpointDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var endpointManager = EndpointManager.shared
    let endpoint: Endpoint
    @State private var name: String
    @State private var url: String
    @State private var showingDeleteAlert = false
    
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
        _name = State(initialValue: endpoint.name)
        _url = State(initialValue: endpoint.url)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("URL", text: $url)
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Endpoint", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Edit Endpoint")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    endpointManager.updateEndpoint(endpoint, name: name, url: url)
                    dismiss()
                }
            }
        }
        .alert("Delete Endpoint", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                endpointManager.removeEndpoint(endpoint)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this endpoint? This action cannot be undone.")
        }
    }
} 
