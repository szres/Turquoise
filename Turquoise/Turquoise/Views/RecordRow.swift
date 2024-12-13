import SwiftUI

struct RecordRow: View {
    let record: PortalRecord
    @State private var showMap = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.portalName)
                    .font(.subheadline)
                Spacer()
                Button {
                    showMap.toggle()
                } label: {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                }
            }
            Text(record.portalAddress)
                .font(.caption)
            HStack {
                Text("Agent: \(record.agentName)")
                Spacer()
                Text(record.timestamp.formatted())
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            
            if showMap {
                RecordMapView(record: record)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecordRow(record: .preview)
        .padding()
} 