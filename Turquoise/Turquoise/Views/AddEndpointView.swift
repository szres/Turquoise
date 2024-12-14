import SwiftUI

struct AddEndpointView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var endpointManager = EndpointManager.shared
    
    @State private var name = ""
    @State private var url = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("URL", text: $url)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
            }
        }
        .navigationTitle("New Endpoint")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    endpointManager.addEndpoint(name: name, url: url)
                    dismiss()
                }
                .disabled(name.isEmpty || url.isEmpty)
            }
        }
    }
} 