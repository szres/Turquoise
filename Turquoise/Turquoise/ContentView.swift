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
    }
}

#Preview {
    ContentView()
}

