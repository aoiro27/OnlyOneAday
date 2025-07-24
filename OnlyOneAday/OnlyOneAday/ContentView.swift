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
    @EnvironmentObject var familyGoalManager: FamilyGoalManager

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
            
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("目標")
                }
                .tag(2)
            
            RewardsView()
                .tabItem {
                    Image(systemName: "gift")
                    Text("報酬")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StudySession.self, Goal.self, Reward.self], inMemory: true)
        .environmentObject(FamilyGoalManager())
}
