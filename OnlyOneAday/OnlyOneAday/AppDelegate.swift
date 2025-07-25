//
//  AppDelegate.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/24.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // アプリ起動時にバッジをリセット
        application.applicationIconBadgeNumber = 0
        
        // 通知センターのデリゲートを設定
        UNUserNotificationCenter.current().delegate = self
        
        // 通知許可をリクエスト
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ 通知許可が承認されました")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("❌ 通知許可が拒否されました")
            }
        }
        
        return true
    }
    
    // デバイストークンの取得成功時
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 デバイストークン取得成功:")
        print("Token: \(tokenString)")
        print("Token Length: \(deviceToken.count) bytes")
        
        // SettingsManagerにデバイストークンを保存
        SettingsManager.shared.deviceToken = tokenString
    }
    
    // デバイストークンの取得失敗時
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ デバイストークン取得失敗:")
        print("Error: \(error.localizedDescription)")
    }
    
    // バックグラウンドで通知を受信した場合（重要！）
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📨 バックグラウンドで通知を受信:")
        print("UserInfo: \(userInfo)")
        
        // 通知の内容を処理
        if let aps = userInfo["aps"] as? [String: Any] {
            print("APS: \(aps)")
            
            // content-availableの確認
            if let contentAvailable = aps["content-available"] as? Int {
                print("Content-Available: \(contentAvailable)")
            } else {
                print("⚠️ Content-Available が設定されていません")
            }
            
            if let alert = aps["alert"] as? [String: Any] {
                print("Title: \(alert["title"] ?? "No title")")
                print("Body: \(alert["body"] ?? "No body")")
            } else if let alert = aps["alert"] as? String {
                print("Alert: \(alert)")
            }
            
            if let badge = aps["badge"] as? Int {
                print("Badge: \(badge)")
            }
            
            if let sound = aps["sound"] as? String {
                print("Sound: \(sound)")
            }
        }
        
        // カスタムデータの処理
        if let customData = userInfo["custom_data"] as? String {
            print("Custom Data: \(customData)")
        }
        
        // バックグラウンド処理の完了を通知
        // 新しいデータがある場合は .newData、ない場合は .noData、エラーの場合は .failed
        completionHandler(.newData)
    }
    
    // フォアグラウンドで通知を受信した場合
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📨 フォアグラウンドで通知を受信:")
        print("Title: \(notification.request.content.title)")
        print("Body: \(notification.request.content.body)")
        print("UserInfo: \(notification.request.content.userInfo)")
        
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound, .badge])
    }
    
    // アプリがフォアグラウンドに戻った時
    func applicationWillEnterForeground(_ application: UIApplication) {
        // バッジをリセット
        application.applicationIconBadgeNumber = 0
    }
    
    // アプリがアクティブになった時
    func applicationDidBecomeActive(_ application: UIApplication) {
        // バッジをリセット
        application.applicationIconBadgeNumber = 0
    }
    
    // 通知をタップした場合
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 通知がタップされました:")
        print("Title: \(response.notification.request.content.title)")
        print("Body: \(response.notification.request.content.body)")
        print("UserInfo: \(response.notification.request.content.userInfo)")
        
        completionHandler()
    }
}
