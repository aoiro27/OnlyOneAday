import Foundation
import SwiftData
import Combine

@Model
final class Partner {
    var id: UUID
    var name: String
    var deviceToken: String?
    var isConnected: Bool
    var lastSyncDate: Date?
    var createdAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.deviceToken = nil
        self.isConnected = false
        self.createdAt = Date()
    }
}

@MainActor
class PartnerManager: ObservableObject {
    @Published var currentPartner: Partner?
    @Published var isConnecting = false
    @Published var connectionError: String?
    
    let modelContext: ModelContext
    private let notificationManager = NotificationManager.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentPartner()
    }
    
    // 現在のパートナーを読み込み
    private func loadCurrentPartner() {
        let descriptor = FetchDescriptor<Partner>()
        if let partners = try? modelContext.fetch(descriptor), let firstPartner = partners.first {
            currentPartner = firstPartner
        }
    }
    
    // パートナーを追加
    func addPartner(name: String) {
        let partner = Partner(name: name)
        modelContext.insert(partner)
        currentPartner = partner
        
        // デバイストークンをサーバーに送信
        if let deviceToken = UserDefaults.standard.string(forKey: "apns_device_token") {
            APIClient.shared.registerDeviceToken(token: deviceToken)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("パートナーの保存に失敗: \(error)")
        }
    }
    
    // パートナーを削除
    func removePartner() {
        guard let partner = currentPartner else { return }
        
        modelContext.delete(partner)
        currentPartner = nil
        
        do {
            try modelContext.save()
        } catch {
            print("パートナーの削除に失敗: \(error)")
        }
    }
    
    // パートナーとの接続を開始
    func connectToPartner(partnerCode: String) async {
        isConnecting = true
        connectionError = nil
        
        // サーバーとの通信でパートナーコードを検証
        await withCheckedContinuation { continuation in
            APIClient.shared.connectToPartner(partnerCode: partnerCode) { success, error in
                Task { @MainActor in
                    if success {
                        // 接続成功
                        self.currentPartner?.isConnected = true
                        self.currentPartner?.lastSyncDate = Date()
                        
                        do {
                            try self.modelContext.save()
                        } catch {
                            print("Failed to save partner connection: \(error)")
                        }
                        
                        // 通知の許可をリクエスト
                        await self.notificationManager.requestAuthorization()
                    } else {
                        self.connectionError = error ?? "接続に失敗しました"
                    }
                    
                    self.isConnecting = false
                    continuation.resume()
                }
            }
        }
    }
    
    // パートナーコードを生成
    func generatePartnerCode() -> String {
        // サーバーからパートナーコードを取得する場合は、ここでAPIClientを使用
        // 現在はローカルで生成
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in letters.randomElement()! })
    }
    
    // 目標達成時にパートナーに通知
    func notifyPartnerGoalCompletion(goalTitle: String) {
        guard let partner = currentPartner, partner.isConnected else { return }
        
        // ローカル通知も送信
        notificationManager.sendPartnerGoalCompletionNotification(
            partnerName: partner.name,
            goalTitle: goalTitle
        )
        
        // サーバー経由でパートナーにプッシュ通知を送信
        APIClient.shared.notifyPartner(
            partnerId: partner.id.uuidString,
            goalTitle: goalTitle,
            goalType: "personal"
        )
    }
    
    // ファミリー目標達成時に通知
    func notifyFamilyGoalCompletion(goalTitle: String) {
        // ローカル通知も送信
        notificationManager.sendFamilyGoalCompletionNotification(goalTitle: goalTitle)
        
        // サーバー経由でファミリー目標達成通知を送信
        APIClient.shared.notifyFamilyGoalCompletion(goalTitle: goalTitle)
    }
} 