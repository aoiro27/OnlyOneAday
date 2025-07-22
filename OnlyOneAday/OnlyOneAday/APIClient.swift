import Foundation

class APIClient {
    static let shared = APIClient()
    
    // サーバーのベースURL
    private let baseURL = APIConfig.baseURL
    
    private init() {}
    
    // デバイストークンをサーバーに登録
    func registerDeviceToken(token: String) {
        guard let url = URL(string: "\(baseURL)\(APIConfig.Endpoints.registerDeviceToken)") else {
            print("Invalid URL for device token registration")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.Headers.contentType, forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "device_token": token,
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize device token registration body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Device token registration failed: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Device token registration response: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // パートナーに目標達成通知を送信
    func notifyPartner(partnerId: String, goalTitle: String, goalType: String = "personal") {
        guard let url = URL(string: "\(baseURL)\(APIConfig.Endpoints.notifyPartner)") else {
            print("Invalid URL for partner notification")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.Headers.contentType, forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "partner_id": partnerId,
            "goal_title": goalTitle,
            "goal_type": goalType,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize partner notification body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Partner notification failed: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Partner notification response: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // ファミリー目標達成通知を送信
    func notifyFamilyGoalCompletion(goalTitle: String) {
        guard let url = URL(string: "\(baseURL)\(APIConfig.Endpoints.notifyFamilyGoal)") else {
            print("Invalid URL for family goal notification")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.Headers.contentType, forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "goal_title": goalTitle,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize family goal notification body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Family goal notification failed: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Family goal notification response: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // パートナーとの接続を確立
    func connectToPartner(partnerCode: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)\(APIConfig.Endpoints.connectPartner)") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.Headers.contentType, forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "partner_code": partnerCode
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false, "Failed to serialize request")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, nil)
                    } else {
                        completion(false, "Connection failed with status: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "Invalid response")
                }
            }
        }.resume()
    }
    
    // パートナーコードを生成
    func generatePartnerCode(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)\(APIConfig.Endpoints.generatePartnerCode)") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.Headers.contentType, forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to generate partner code: \(error)")
                    completion(nil)
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let partnerCode = json["partner_code"] as? String {
                    completion(partnerCode)
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
} 