//
//  UserGoalManager.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/01/27.
//

import Foundation
import SwiftUI

class UserGoalManager: ObservableObject {
    private let api = UserGoalAPI()
    
    @Published var userGoals: [UserGoalInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // ユーザーIDを取得（デバイス固有のIDを使用）
    private var userId: String {
        if let existingId = UserDefaults.standard.string(forKey: "userId") {
            return existingId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "userId")
            return newId
        }
    }
    
    init() {
        // 初期化時に目標一覧を取得
        Task {
            await fetchUserGoals()
        }
    }
    
    // 個人目標一覧を取得
    @MainActor
    func fetchUserGoals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            userGoals = try await api.getUserGoals(userId: userId)
            print("個人目標一覧を取得しました: \(userGoals.count)件")
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to fetch user goals: \(error)")
        }
        
        isLoading = false
    }
    
    // 個人目標を作成
    @MainActor
    func createUserGoal(title: String, detail: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.createUserGoal(userId: userId, title: title, detail: detail)
            print("個人目標を作成しました: \(response.goalId)")
            
            // 目標一覧を再取得
            await fetchUserGoals()
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to create user goal: \(error)")
            return false
        }
    }
    
    // 個人目標を更新
    @MainActor
    func updateUserGoal(goalId: String, title: String? = nil, detail: String? = nil, isCompleted: Bool? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.updateUserGoal(
                userId: userId,
                goalId: goalId,
                title: title,
                detail: detail,
                isCompleted: isCompleted
            )
            print("個人目標を更新しました: \(response.goalId)")
            
            // 目標一覧を再取得
            await fetchUserGoals()
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to update user goal: \(error)")
            return false
        }
    }
    
    // 個人目標を削除
    @MainActor
    func deleteUserGoal(goalId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.deleteUserGoal(userId: userId, goalId: goalId)
            print("個人目標を削除しました: \(response.goalId)")
            
            // 目標一覧を再取得
            await fetchUserGoals()
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to delete user goal: \(error)")
            return false
        }
    }
    
    // 目標を完了状態に変更
    @MainActor
    func completeUserGoal(goalId: String) async -> Bool {
        return await updateUserGoal(goalId: goalId, isCompleted: true)
    }
    
    // 目標を未完了状態に変更
    @MainActor
    func uncompleteUserGoal(goalId: String) async -> Bool {
        return await updateUserGoal(goalId: goalId, isCompleted: false)
    }
    
    // 完了済みの目標を取得
    var completedGoals: [UserGoalInfo] {
        return userGoals.filter { $0.isCompleted }
    }
    
    // 未完了の目標を取得
    var incompleteGoals: [UserGoalInfo] {
        return userGoals.filter { !$0.isCompleted }
    }
    
    // 目標の完了率を計算
    var completionRate: Double {
        guard !userGoals.isEmpty else { return 0.0 }
        return Double(completedGoals.count) / Double(userGoals.count)
    }
} 