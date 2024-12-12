//
//  RuleSetListView.swift
//  Turquoise
//
//  Created by 罗板栗 on 2024/12/12.
//

import SwiftUI

struct RuleSetListView: View {
    var endpoint: Endpoint?
    @StateObject private var endpointManager = EndpointManager()
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
                            RuleSetRow(ruleSet: ruleSet, endpointManager: endpointManager)
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
            isRefreshing = true
            if let endpoint = endpoint {
                endpointManager.loadRuleSets(for: endpoint)
            }
            isRefreshing = false
        }
        .onAppear {
            if let endpoint = endpoint {
                endpointManager.loadRuleSets(for: endpoint)
            }
        }
    }
}

struct RuleSetRow: View {
    let ruleSet: RuleSet
    @StateObject private var endpointManager: EndpointManager
    @State private var isSubscribed: Bool
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    init(ruleSet: RuleSet, endpointManager: EndpointManager) {
        self.ruleSet = ruleSet
        self._endpointManager = StateObject(wrappedValue: endpointManager)
        self._isSubscribed = State(initialValue: ruleSet.isSubscribed)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ruleSet.name)
                    .font(.headline)
                Spacer()
                if isUpdating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Toggle("", isOn: $isSubscribed)
                        .labelsHidden()
                        .tint(.green)
                        .onChange(of: isSubscribed) {
                            updateSubscription()
                        }
                }
            }
            
            Text(ruleSet.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                if let lastRecord = ruleSet.lastRecordAt {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(lastRecord.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.secondary)
                    Text("\(ruleSet.recordCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Subscription Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
                isSubscribed.toggle()  // 恢复原始状态
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func updateSubscription() {
        isUpdating = true
        Task {
            do {
                if isSubscribed {
                    try await SubscriptionService.shared.subscribe(ruleSetId: ruleSet.uuid)
                } else {
                    try await SubscriptionService.shared.unsubscribe(ruleSetId: ruleSet.uuid)
                }
                
                await MainActor.run {
                    var updatedRuleSet = ruleSet
                    updatedRuleSet.isSubscribed = isSubscribed
                    endpointManager.updateSubscription(updatedRuleSet)
                    isUpdating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isUpdating = false
                }
            }
        }
    }
}

#Preview {
    RuleSetListView()
}
