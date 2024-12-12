//
//  SettingsView.swift
//  Turquoise
//
//  Created by 罗板栗 on 2024/12/12.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var isAddingEndpoint = false
    @State private var newEndpointName = ""
    @State private var newEndpointURL = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Endpoints")) {
                    ForEach(endpointManager.endpoints) { endpoint in
                        VStack(alignment: .leading) {
                            Text(endpoint.name)
                                .font(.headline)
                            Text(endpoint.url)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: endpointManager.removeEndpoint)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingEndpoint = true }) {
                        Label("Add Endpoint", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingEndpoint) {
                NavigationView {
                    Form {
                        Section {
                            TextField("Name", text: $newEndpointName)
                            TextField("URL", text: $newEndpointURL)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                        }
                        
                        Section {
                            Button("Add") {
                                endpointManager.addEndpoint(
                                    name: newEndpointName,
                                    url: newEndpointURL
                                )
                                newEndpointName = ""
                                newEndpointURL = ""
                                isAddingEndpoint = false
                            }
                            .disabled(newEndpointName.isEmpty || newEndpointURL.isEmpty)
                        }
                    }
                    .navigationTitle("New Endpoint")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            isAddingEndpoint = false
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
