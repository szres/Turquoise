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
    @State private var editingEndpoint: Endpoint?
    
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
                        .contextMenu {
                            Button {
                                editingEndpoint = endpoint
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                endpointManager.removeEndpoint(endpoint)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: endpointManager.removeEndpoint(at:))
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
                EndpointFormView(
                    mode: .add,
                    isPresented: $isAddingEndpoint,
                    endpoint: nil,
                    onSave: { name, url in
                        endpointManager.addEndpoint(name: name, url: url)
                    }
                )
            }
            .sheet(item: $editingEndpoint) { endpoint in
                EndpointFormView(
                    mode: .edit,
                    isPresented: Binding(
                        get: { editingEndpoint != nil },
                        set: { if !$0 { editingEndpoint = nil } }
                    ),
                    endpoint: endpoint,
                    onSave: { name, url in
                        endpointManager.updateEndpoint(endpoint, name: name, url: url)
                        editingEndpoint = nil
                    }
                )
            }
        }
    }
}

enum EndpointFormMode {
    case add
    case edit
}

struct EndpointFormView: View {
    let mode: EndpointFormMode
    @Binding var isPresented: Bool
    let endpoint: Endpoint?
    let onSave: (String, String) -> Void
    
    @State private var name: String = ""
    @State private var url: String = ""
    
    init(mode: EndpointFormMode, isPresented: Binding<Bool>, endpoint: Endpoint?, onSave: @escaping (String, String) -> Void) {
        self.mode = mode
        self._isPresented = isPresented
        self.endpoint = endpoint
        self.onSave = onSave
        
        if let endpoint = endpoint {
            _name = State(initialValue: endpoint.name)
            _url = State(initialValue: endpoint.url)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("URL", text: $url)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }
                
                Section {
                    Button("Save") {
                        onSave(name, url)
                        isPresented = false
                    }
                    .disabled(name.isEmpty || url.isEmpty)
                }
            }
            .navigationTitle(mode == .add ? "New Endpoint" : "Edit Endpoint")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
}

#Preview {
    SettingsView()
}
