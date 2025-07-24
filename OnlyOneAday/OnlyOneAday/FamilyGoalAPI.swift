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

// APIクライアントクラス
class FamilyGoalAPI {
    private let baseURL = "https://update-family-mission-488889291017.asia-northeast1.run.app"
    
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
            return "ファミリーIDが設定されていません"
        }
    }
} 
