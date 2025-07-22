//
//  OnlyOneAdayApp.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct OnlyOneAdayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudySession.self,
            StudyCategory.self,
            Goal.self,
            Reward.self,
            FamilyGoal.self,
            Partner.self,
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
                .onAppear {
                    // アプリ起動時に通知の許可をリクエスト
                    Task {
                        await NotificationManager.shared.requestAuthorization()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
