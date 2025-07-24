//
//  FamilyGoalAPI.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import Foundation

// APIレスポンス用の構造体
struct FamilyMissionResponse: Codable {
    let docId: String
    let mission: String
    let isCleared: Bool
    
    enum CodingKeys: String, CodingKey {
        case docId = "doc_id"
        case mission
        case isCleared = "isCleared"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 必須フィールド
        docId = try container.decode(String.self, forKey: .docId)
        isCleared = try container.decode(Bool.self, forKey: .isCleared)
        
        // missionフィールドが存在しない場合は空文字列を使用
        mission = try container.decodeIfPresent(String.self, forKey: .mission) ?? ""
    }
    
    // 手動でインスタンスを作成するためのイニシャライザー
    init(docId: String, mission: String, isCleared: Bool) {
        self.docId = docId
        self.mission = mission
        self.isCleared = isCleared
    }
}

// 更新時のAPIレスポンス用の構造体
struct UpdateMissionResponse: Codable {
    let result: String
    let docId: String
    
    enum CodingKeys: String, CodingKey {
        case result
        case docId = "doc_id"
    }
}

// APIリクエスト用の構造体
struct CreateFamilyMissionRequest: Codable {
    let familyId: String
    let mission: String
    let isCleared: Bool
    
    enum CodingKeys: String, CodingKey {
        case familyId = "familyId"
        case mission
        case isCleared = "isCleared"
    }
}

struct UpdateFamilyMissionRequest: Codable {
    let familyId: String
    let docId: String
    let mission: String
    let isCleared: Bool
    
    enum CodingKeys: String, CodingKey {
        case familyId = "familyId"
        case docId = "doc_id"
        case mission
        case isCleared = "isCleared"
    }
}

// ファミリーメンバー管理用のリクエスト構造体
struct FamilyMemberRequest: Codable {
    let name: String
    let deviceToken: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case deviceToken
    }
}

// ファミリーメンバー管理用のレスポンス構造体
struct FamilyMemberResponse: Codable {
    let result: String
    let memberId: String
    
    enum CodingKeys: String, CodingKey {
        case result
        case memberId
    }
}

// ファミリーメンバー情報構造体
struct FamilyMemberInfo: Codable {
    let name: String
    let memberId: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case memberId
    }
}

// ファミリー状況情報構造体
struct FamilyStatusInfo: Codable {
    let familyId: String
    let memberId: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case familyId = "familyId"
        case memberId = "memberId"
        case name
    }
}

// APIクライアントクラス
class FamilyGoalAPI {
    private let baseURL = "https://update-family-mission-488889291017.asia-northeast1.run.app"
    private let familyManagementURL = "https://management-family-488889291017.asia-northeast1.run.app"
    
    // ファミリーID（設定から取得）
    private var familyId: String? {
        return UserDefaults.standard.string(forKey: "familyId")
    }
    
    // ミッション一覧取得
    func fetchFamilyMissions() async throws -> [FamilyMissionResponse] {
        guard let familyId = familyId else {
            throw APIError.familyIdNotSet
        }
        
        guard let url = URL(string: "\(baseURL)?familyId=\(familyId)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let missions = try JSONDecoder().decode([FamilyMissionResponse].self, from: data)
            return missions
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // ミッション新規作成
    func createFamilyMission(mission: String) async throws -> UpdateMissionResponse {
        guard let familyId = familyId else {
            throw APIError.familyIdNotSet
        }
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        let request = CreateFamilyMissionRequest(
            familyId: familyId,
            mission: mission,
            isCleared: false
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let response = try JSONDecoder().decode(UpdateMissionResponse.self, from: data)
            return response
        } catch {
            // デバッグ用：レスポンスの内容を出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            throw APIError.decodingError(error)
        }
    }
    
    // ミッション削除
    func deleteFamilyMission(docId: String) async throws -> UpdateMissionResponse {
        guard let familyId = familyId else {
            throw APIError.familyIdNotSet
        }
        
        guard let url = URL(string: "\(baseURL)?familyId=\(familyId)&doc_id=\(docId)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let response = try JSONDecoder().decode(UpdateMissionResponse.self, from: data)
            return response
        } catch {
            // デバッグ用：レスポンスの内容を出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            throw APIError.decodingError(error)
        }
    }
    
    // ミッション更新
    func updateFamilyMission(docId: String, mission: String, isCleared: Bool) async throws -> UpdateMissionResponse {
        guard let familyId = familyId else {
            throw APIError.familyIdNotSet
        }
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        let request = UpdateFamilyMissionRequest(
            familyId: familyId,
            docId: docId,
            mission: mission,
            isCleared: isCleared
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let response = try JSONDecoder().decode(UpdateMissionResponse.self, from: data)
            return response
        } catch {
            // デバッグ用：レスポンスの内容を出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            throw APIError.decodingError(error)
        }
    }
    
    // ファミリーメンバー追加（ファミリー作成・参加）
    func addFamilyMember(familyId: String, name: String) async throws -> FamilyMemberResponse {
        guard let url = URL(string: "\(familyManagementURL)/members?familyId=\(familyId)") else {
            throw APIError.invalidURL
        }
        
        // SettingsManagerからデバイストークンを取得
        let deviceToken = SettingsManager.shared.deviceToken.isEmpty ? nil : SettingsManager.shared.deviceToken
        
        let request = FamilyMemberRequest(name: name, deviceToken: deviceToken)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let memberResponse = try JSONDecoder().decode(FamilyMemberResponse.self, from: data)
            return memberResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // ファミリーメンバー削除（ファミリー脱退）
    func removeFamilyMember(familyId: String, memberId: String) async throws -> FamilyMemberResponse {
        guard let url = URL(string: "\(familyManagementURL)/members?familyId=\(familyId)&memberId=\(memberId)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let memberResponse = try JSONDecoder().decode(FamilyMemberResponse.self, from: data)
            return memberResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // ファミリーメンバー更新（デバイストークン更新など）
    func updateFamilyMember(familyId: String, memberId: String, name: String) async throws -> FamilyMemberResponse {
        guard let url = URL(string: "\(familyManagementURL)/members?familyId=\(familyId)") else {
            throw APIError.invalidURL
        }
        
        // SettingsManagerからデバイストークンを取得
        let deviceToken = SettingsManager.shared.deviceToken.isEmpty ? nil : SettingsManager.shared.deviceToken
        
        // PUTメソッドではmemberIdもリクエストボディに含める必要がある
        var requestData: [String: Any] = [
            "name": name,
            "memberId": memberId
        ]
        
        if let deviceToken = deviceToken {
            requestData["deviceToken"] = deviceToken
        }
        
        // デバッグ情報を出力
        print("🔧 デバッグ情報:")
        print("  - URL: \(url)")
        print("  - familyId: \(familyId)")
        print("  - memberId: \(memberId)")
        print("  - name: \(name)")
        print("  - deviceToken: \(deviceToken ?? "nil")")
        print("  - requestData: \(requestData)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let memberResponse = try JSONDecoder().decode(FamilyMemberResponse.self, from: data)
            return memberResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // ファミリーメンバー一覧取得
    func getFamilyMembers(familyId: String) async throws -> [FamilyMemberInfo] {
        guard let url = URL(string: "\(familyManagementURL)/members?familyId=\(familyId)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let members = try JSONDecoder().decode([FamilyMemberInfo].self, from: data)
            return members
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // ファミリー状況取得（ローカルに保存されたfamilyIdを使用）
    func getFamilyStatus() async throws -> FamilyStatusInfo? {
        guard let familyId = UserDefaults.standard.string(forKey: "familyId") else {
            return nil
        }
        
        let members = try await getFamilyMembers(familyId: familyId)
        // 最初のメンバーをファミリー状況として返す（簡易実装）
        return members.first.map { member in
            FamilyStatusInfo(
                familyId: familyId,
                memberId: member.memberId,
                name: member.name
            )
        }
    }
}

// APIエラー定義
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case familyIdNotSet
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let code):
            return "サーバーエラー: \(code)"
        case .encodingError(let error):
            return "エンコーディングエラー: \(error.localizedDescription)"
        case .decodingError(let error):
            return "デコーディングエラー: \(error.localizedDescription)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .familyIdNotSet:
            return "名前とファミリーIDが設定されていません"
        }
    }
} 
