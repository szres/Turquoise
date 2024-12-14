import SwiftUI
import SwiftData

struct RuleSetSubscribeRow: View {
    @Bindable var ruleSet: RuleSet
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
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
                    Toggle("", isOn: $ruleSet.isSubscribed)
                        .labelsHidden()
                        .tint(.green)
                        .onChange(of: ruleSet.isSubscribed) {
                            updateSubscription()
                        }
                }
            }
            
            Text(ruleSet.ruleDescription)
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
                ruleSet.isSubscribed.toggle()  // 恢复原始状态
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            Task {
                do {
                    let topics = try await SubscriptionService.shared.fetchSubscribedTopics()
                    await MainActor.run {
                        ruleSet.isSubscribed = topics.contains(ruleSet.uuid)
                        endpointManager.updateRuleSet(ruleSet)
                    }
                } catch {
                    print("Failed to sync subscription status: \(error)")
                }
            }
        }
    }
    
    private func updateSubscription() {
        isUpdating = true
        Task {
            do {
                if ruleSet.isSubscribed {
                    try await SubscriptionService.shared.subscribe(ruleSetId: ruleSet.uuid)
                } else {
                    try await SubscriptionService.shared.unsubscribe(ruleSetId: ruleSet.uuid)
                }
                
                await MainActor.run {
                    endpointManager.updateRuleSet(ruleSet)
                    isUpdating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    ruleSet.isSubscribed.toggle()  // 恢复原始状态
                    isUpdating = false
                }
            }
        }
    }
}

#Preview {
    RuleSetSubscribeRow(ruleSet: RuleSet.preview)
        .padding()
} 