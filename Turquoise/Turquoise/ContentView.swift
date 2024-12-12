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
            RuleSetListView()
                .tabItem {
                    Label("Rules", systemImage: "list.bullet")
                }
            
            EndPointView()
                .tabItem {
                    Label("Subscribe", systemImage: "plus.circle")
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

