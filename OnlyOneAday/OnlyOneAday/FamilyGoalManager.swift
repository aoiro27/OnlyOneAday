//
//  FamilyGoalManager.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import Foundation
import SwiftUI

@MainActor
class FamilyGoalManager: ObservableObject {
    @Published var familyMissions: [FamilyMissionResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFamilyIdSet: Bool = false
    
    private let api = FamilyGoalAPI()
    
    init() {
        checkFamilyId()
    }
    
    func checkFamilyId() {
        let familyId = UserDefaults.standard.string(forKey: "familyId")
        let userName = UserDefaults.standard.string(forKey: "userName")
        isFamilyIdSet = familyId != nil && !familyId!.isEmpty && userName != nil && !userName!.isEmpty
    }
    
    // ファミリー目標を取得
    func fetchFamilyMissions() async {
        checkFamilyId()
        
        if !isFamilyIdSet {
            errorMessage = "名前とファミリーIDが設定されていません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            familyMissions = try await api.fetchFamilyMissions()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to fetch family missions: \(error)")
        }
        
        isLoading = false
    }
    
    // ファミリー目標を新規作成
    func createFamilyMission(mission: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.createFamilyMission(mission: mission)
            
            // 新しいミッションを作成してローカル配列に追加
            let newMission = FamilyMissionResponse(
                docId: response.docId,
                mission: mission,
                isCleared: false
            )
            familyMissions.append(newMission)
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to create family mission: \(error)")
            isLoading = false
            return false
        }
    }
    
    // ファミリー目標を更新
    func updateFamilyMission(docId: String, mission: String, isCleared: Bool) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.updateFamilyMission(
                docId: docId,
                mission: mission,
                isCleared: isCleared
            )
            
            // ローカルの配列を更新
            if let index = familyMissions.firstIndex(where: { $0.docId == docId }) {
                familyMissions[index] = FamilyMissionResponse(
                    docId: response.docId,
                    mission: mission,
                    isCleared: isCleared
                )
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to update family mission: \(error)")
            isLoading = false
            return false
        }
    }
    
    // 完了済みのミッションを取得
    var completedMissions: [FamilyMissionResponse] {
        familyMissions.filter { $0.isCleared }
    }
    
    // 未完了のミッションを取得
    var incompleteMissions: [FamilyMissionResponse] {
        familyMissions.filter { !$0.isCleared }
    }
    
    // 全てのミッションが完了しているかチェック
    var allMissionsCompleted: Bool {
        !familyMissions.isEmpty && familyMissions.allSatisfy { $0.isCleared }
    }
    
    // ファミリー目標を削除
    func deleteFamilyMission(docId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await api.deleteFamilyMission(docId: docId)
            
            // ローカルの配列から削除
            familyMissions.removeAll { $0.docId == docId }
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to delete family mission: \(error)")
            isLoading = false
            return false
        }
    }
    
    // 進捗率を計算
    var progress: Double {
        guard !familyMissions.isEmpty else { return 0 }
        return Double(completedMissions.count) / Double(familyMissions.count)
    }
} 