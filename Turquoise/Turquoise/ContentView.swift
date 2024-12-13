//
//  ContentView.swift
//  Turquoise
//
//  Created by 罗板栗 on 2024/12/12.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NotificationView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                
            SubscriptionListView()
                .tabItem {
                    Label("Subscribed", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 500)
        #endif
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}

