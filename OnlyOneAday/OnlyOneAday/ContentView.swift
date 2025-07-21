//
//  ContentView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GitHubContributionsView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("GitHub")
                }
                .tag(0)
            
            StudyView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("学習")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StudySession.self], inMemory: true)
}
