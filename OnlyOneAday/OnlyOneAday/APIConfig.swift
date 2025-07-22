import Foundation

struct APIConfig {
    // サーバーのベースURL（開発環境）
    static let developmentBaseURL = "https://asia-northeast1-your-gcp-project-id.cloudfunctions.net/only-one-a-day-api"
    
    // サーバーのベースURL（本番環境）
    static let productionBaseURL = "https://asia-northeast1-your-gcp-project-id.cloudfunctions.net/only-one-a-day-api"
    
    // 現在の環境に応じたベースURLを取得
    static var baseURL: String {
        #if DEBUG
        return developmentBaseURL
        #else
        return productionBaseURL
        #endif
    }
    
    // API エンドポイント
    struct Endpoints {
        static let registerDeviceToken = "/register_device_token"
        static let notifyPartner = "/notify_partner"
        static let notifyFamilyGoal = "/notify_family_goal"
        static let connectPartner = "/connect_partner"
        static let generatePartnerCode = "/generate_partner_code"
    }
    
    // ヘッダー
    struct Headers {
        static let contentType = "application/json"
        static let authorization = "Bearer YOUR_API_KEY" // 必要に応じてAPIキーを設定
    }
} 