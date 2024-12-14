//
//  SettingsView.swift
//  Turquoise
//
//  Created by 罗板栗 on 2024/12/12.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var endpointManager = EndpointManager.shared
    @Query(sort: \Endpoint.createdAt) private var endpoints: [Endpoint]
    
    var body: some View {
        NavigationView {
            List {
                Section("Endpoints") {
                    ForEach(endpoints) { endpoint in
                        NavigationLink(destination: EndpointDetailView(endpoint: endpoint)) {
                            VStack(alignment: .leading) {
                                Text(endpoint.name)
                                    .font(.headline)
                                Text(endpoint.url)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            endpointManager.removeEndpoint(endpoints[index])
                        }
                    }
                    
                    NavigationLink(destination: AddEndpointView()) {
                        Label("Add Endpoint", systemImage: "plus.circle")
                    }
                }
                
                Section("Device") {
                    if let token = UserDefaults.standard.string(forKey: "APNSDeviceToken") {
                        Text("Device Token")
                            .font(.headline)
                        Text(token)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    } else {
                        Text("Device Token not available")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            endpointManager.setModelContext(modelContext)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Endpoint.self, RuleSet.self])
}
