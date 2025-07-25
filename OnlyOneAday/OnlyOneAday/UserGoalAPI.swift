//
//  UserGoalAPI.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/01/27.
//

import Foundation

// MARK: - Request/Response Models

struct UserGoalRequest: Codable {
    let title: String
    let detail: String?
    let isCompleted: Bool
    let createdAt: String?
}

struct UserGoalResponse: Codable {
    let result: String
    let goalId: String
}

struct UserGoalInfo: Codable {
    let title: String
    let detail: String?
    let isCompleted: Bool
    let createdAt: String?
    let goalId: String
}

// MARK: - API Client

class UserGoalAPI {
    private let baseURL = "https://update-user-mission-488889291017.asia-northeast1.run.app"
    
    // 個人目標を作成
    func createUserGoal(userId: String, title: String, detail: String? = nil) async throws -> UserGoalResponse {
        guard let url = URL(string: "\(baseURL)/goals?userId=\(userId)") else {
            throw APIError.invalidURL
        }
        
        let request = UserGoalRequest(
            title: title,
            detail: detail,
            isCompleted: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(UserGoalResponse.self, from: data)
    }
    
    // 個人目標を更新
    func updateUserGoal(userId: String, goalId: String, title: String? = nil, detail: String? = nil, isCompleted: Bool? = nil) async throws -> UserGoalResponse {
        guard let url = URL(string: "\(baseURL)/goals?userId=\(userId)&goalId=\(goalId)") else {
            throw APIError.invalidURL
        }
        
        var requestData: [String: Any] = [:]
        if let title = title {
            requestData["title"] = title
        }
        if let detail = detail {
            requestData["detail"] = detail
        }
        if let isCompleted = isCompleted {
            requestData["isCompleted"] = isCompleted
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(UserGoalResponse.self, from: data)
    }
    
    // 個人目標を削除
    func deleteUserGoal(userId: String, goalId: String) async throws -> UserGoalResponse {
        guard let url = URL(string: "\(baseURL)/goals?userId=\(userId)&goalId=\(goalId)") else {
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
        
        return try JSONDecoder().decode(UserGoalResponse.self, from: data)
    }
    
    // 個人目標一覧を取得
    func getUserGoals(userId: String) async throws -> [UserGoalInfo] {
        guard let url = URL(string: "\(baseURL)/goals?userId=\(userId)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([UserGoalInfo].self, from: data)
    }
}

 