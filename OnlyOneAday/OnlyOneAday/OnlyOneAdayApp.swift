//
//  OnlyOneAdayApp.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData

@main
struct OnlyOneAdayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var familyGoalManager = FamilyGoalManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudySession.self,
            StudyCategory.self,
            Goal.self,
            Reward.self,
            GoalAchievementRecord.self,
            FamilyGoalAchievementRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(familyGoalManager)
                .onAppear {
                    // アプリ起動時にファミリー状況を確認し、デバイストークンを更新
                    Task {
                        familyGoalManager.checkLocalFamilyId()
                        if familyGoalManager.isFamilyIdSet {
                            await familyGoalManager.fetchFamilyStatus()
                            // デバイストークンが取得できている場合は更新
                            if SettingsManager.shared.hasDeviceToken() {
                                await familyGoalManager.updateDeviceToken()
                            }
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
