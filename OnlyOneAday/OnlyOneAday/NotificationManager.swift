import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // 通知の許可をリクエスト
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("通知の許可リクエストに失敗: \(error)")
        }
    }
    
    // 通知の許可状態をチェック
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // リモート通知に登録
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // リモート通知の処理
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let body = alert["body"] as? String {
            
            // リモート通知をローカル通知として表示
            sendLocalNotification(title: title, body: body)
        }
    }
    
    // ローカル通知を送信
    func sendLocalNotification(title: String, body: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("ローカル通知の送信に失敗: \(error)")
            }
        }
    }
    
    // パートナーの目標達成通知を送信
    func sendPartnerGoalCompletionNotification(partnerName: String, goalTitle: String) {
        let title = "🎉 パートナーの目標達成！"
        let body = "\(partnerName)さんが「\(goalTitle)」を達成しました！おめでとうございます！"
        
        sendLocalNotification(title: title, body: body)
    }
    
    // ファミリー目標達成通知を送信
    func sendFamilyGoalCompletionNotification(goalTitle: String) {
        let title = "🎉 ファミリー目標達成！"
        let body = "ファミリー目標「\(goalTitle)」を達成しました！家族みんなで協力してくれてありがとう！"
        
        sendLocalNotification(title: title, body: body)
    }
} 