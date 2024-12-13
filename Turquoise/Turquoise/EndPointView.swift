//
//  EndPointView.swift
//  Turquoise
//
//  Created by 罗板栗 on 2024/12/12.
//

import SwiftUI
import SwiftData

struct EndPointView: View {
    @StateObject private var endpointManager = EndpointManager.shared
    @State private var isSyncing = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(endpointManager.endpoints) { endpoint in
                    NavigationLink(destination: RuleSetListView(endpoint: endpoint)) {
                        VStack(alignment: .leading) {
                            Text(endpoint.name)
                                .font(.headline)
                            Text(endpoint.url)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Subscribe")
            .overlay {
                if isSyncing {
                    ProgressView()
                }
            }
            .onAppear {
                // 当页面出现时，同步订阅状态并刷新所有端点的规则集
                Task {
                    isSyncing = true
                    await endpointManager.syncSubscriptions()
                    for endpoint in endpointManager.endpoints {
                        endpointManager.loadRuleSets(for: endpoint)
                    }
                    isSyncing = false
                }
            }
            .refreshable {
                // 下拉刷新时，同步订阅状态并刷新所有端点的规则集
                await endpointManager.syncSubscriptions()
                for endpoint in endpointManager.endpoints {
                    endpointManager.loadRuleSets(for: endpoint)
                }
            }
        }
    }
}

#Preview {
    EndPointView()
}
