import SwiftUI

struct RuleSetRow: View {
    let ruleSet: RuleSet
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ruleSet.name)
                    .font(.headline)
                Spacer()
                Text("\(ruleSet.recordCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(ruleSet.ruleDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 