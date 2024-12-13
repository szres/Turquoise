import SwiftUI
#if os(macOS)
import AppKit
#endif

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
                            NavigationLink(destination: RuleSetDetailView(ruleSet: ruleSet)) {
                                RuleSetRow(ruleSet: ruleSet)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Turquoise")
            .refreshable {
                await refreshSubscriptions()
            }
            #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
        .navigationViewStyle(.columns)
        #endif
    }
    
    private func refreshSubscriptions() {
        Task {
            isLoading = true
            await endpointManager.syncSubscriptions()
            isLoading = false
        }
    }
}



#Preview {
    NavigationView {
        NotificationView()
    }
} 
