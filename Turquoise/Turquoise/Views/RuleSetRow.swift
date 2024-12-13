import SwiftUI

struct RuleSetRow: View {
    let ruleSet: RuleSet
    var showSubscribeButton: Bool = false
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var isSubscribed: Bool
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    init(ruleSet: RuleSet, showSubscribeButton: Bool = false) {
        self.ruleSet = ruleSet
        self.showSubscribeButton = showSubscribeButton
        self._isSubscribed = State(initialValue: ruleSet.isSubscribed)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ruleSet.name)
                    .font(.headline)
                Spacer()
                if showSubscribeButton {
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
                } else {
                    Text("\(ruleSet.recordCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(ruleSet.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if showSubscribeButton {
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
        guard showSubscribeButton else { return }
        
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