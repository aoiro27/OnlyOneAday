import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // アプリ起動時の処理
        return true
    }
    
    // APNs登録成功時の処理
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Device Token: \(tokenString)")
        
        // デバイストークンをUserDefaultsに保存
        UserDefaults.standard.set(tokenString, forKey: "apns_device_token")
        
        // サーバーにデバイストークンを送信
        APIClient.shared.registerDeviceToken(token: tokenString)
    }
    
    // APNs登録失敗時の処理
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // リモート通知受信時の処理
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received remote notification: \(userInfo)")
        
        // NotificationManagerでリモート通知を処理
        NotificationManager.shared.handleRemoteNotification(userInfo)
        
        completionHandler(.newData)
    }
} 