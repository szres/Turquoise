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
            .onAppear {
                // 当页面出现时，刷新所有端点的规则集
                for endpoint in endpointManager.endpoints {
                    endpointManager.loadRuleSets(for: endpoint)
                }
            }
            .refreshable {
                // 下拉刷新时，刷新所有端点的规则集
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
