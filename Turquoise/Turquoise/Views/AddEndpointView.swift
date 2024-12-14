import SwiftUI
import AVFoundation

struct AddEndpointView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var endpointManager = EndpointManager.shared
    
    @State private var name = ""
    @State private var url = ""
    @State private var showingScanner = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("URL", text: $url)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
            }
            
            Section {
                Button {
                    checkCameraPermissionAndShowScanner()
                } label: {
                    Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                }
            }
        }
        .navigationTitle("New Endpoint")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveEndpoint()
                }
                .disabled(name.isEmpty || url.isEmpty)
            }
        }
        .sheet(isPresented: $showingScanner) {
            NavigationView {
                QRScannerView(isPresented: $showingScanner) { name, url in
                    self.name = name
                    self.url = url
                }
                .navigationTitle("Scan QR Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingScanner = false
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveEndpoint() {
        endpointManager.addEndpoint(name: name, url: url)
        name = ""
        url = ""
        dismiss()
    }
    
    private func checkCameraPermissionAndShowScanner() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        showingScanner = true
                    }
                }
            }
        default:
            alertMessage = "Camera access is required to scan QR codes. Please enable it in Settings."
            showingAlert = true
        }
    }
}