//
//  RuleSetListView.swift
//  Turquoise
//
//  Created by 罗板栗 on 2024/12/12.
//

import SwiftUI

struct RuleSetListView: View {
    var endpoint: Endpoint?
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var isRefreshing = false
    
    var body: some View {
        Group {
            switch endpointManager.loadingState {
            case .idle, .loading:
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            case .loaded:
                if endpointManager.subscriptions.isEmpty {
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
                        ForEach(endpointManager.subscriptions) { ruleSet in
                            RuleSetRow(ruleSet: ruleSet, showSubscribeButton: true)
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
                        if let endpoint = endpoint {
                            endpointManager.loadRuleSets(for: endpoint)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle(endpoint?.name ?? "Turquoise")
        .refreshable {
            if let endpoint = endpoint {
                endpointManager.loadRuleSets(for: endpoint)
            }
        }
        .onAppear {
            if let endpoint = endpoint {
                endpointManager.loadRuleSets(for: endpoint)
            }
        }
    }
}

#Preview {
    RuleSetListView()
}
