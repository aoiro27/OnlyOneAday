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
    @Published var familyMembers: [FamilyMemberInfo] = []
    @Published var familyStatus: FamilyStatusInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFamilyIdSet: Bool = false
    
    private let api = FamilyGoalAPI()
    
    init() {
        // 初期化時はローカルチェックのみ
        checkLocalFamilyId()
    }
    
    func checkLocalFamilyId() {
        let familyId = UserDefaults.standard.string(forKey: "familyId")
        let userName = UserDefaults.standard.string(forKey: "userName")
        isFamilyIdSet = familyId != nil && !familyId!.isEmpty && userName != nil && !userName!.isEmpty
    }
    
    // サーバーからファミリー状況を取得
    func fetchFamilyStatus() async {
        do {
            familyStatus = try await api.getFamilyStatus()
            isFamilyIdSet = familyStatus != nil
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to fetch family status: \(error)")
            isFamilyIdSet = false
        }
    }
    
    // ファミリー目標を取得
    func fetchFamilyMissions() async {
        checkLocalFamilyId()
        
        if !isFamilyIdSet {
            errorMessage = "ファミリーに参加していません"
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
    
    // ファミリー作成（ファミリーIDを生成してメンバーを追加）
    func createFamily(userName: String) async -> FamilyStatusInfo? {
        // ファミリーIDを生成（UUIDベース）
        let familyId = UUID().uuidString.prefix(8).uppercased()
        
        do {
            let response = try await api.addFamilyMember(
                familyId: String(familyId),
                name: userName
            )
            
            // ファミリー状況を作成
            let status = FamilyStatusInfo(
                familyId: String(familyId),
                memberId: response.memberId,
                name: userName
            )
            
            // ローカルにユーザー名とファミリーIDを保存
            UserDefaults.standard.set(userName, forKey: "userName")
            UserDefaults.standard.set(String(familyId), forKey: "familyId")
            
            return status
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to create family: \(error)")
            return nil
        }
    }
    
    // ファミリー参加
    func joinFamily(userName: String, familyId: String) async -> FamilyStatusInfo? {
        do {
            let response = try await api.addFamilyMember(
                familyId: familyId,
                name: userName
            )
            
            // ファミリー状況を作成
            let status = FamilyStatusInfo(
                familyId: familyId,
                memberId: response.memberId,
                name: userName
            )
            
            // ローカルにユーザー名とファミリーIDを保存
            UserDefaults.standard.set(userName, forKey: "userName")
            UserDefaults.standard.set(familyId, forKey: "familyId")
            
            return status
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to join family: \(error)")
            return nil
        }
    }
    
    // ファミリー脱退
    func leaveFamily() async -> Bool {
        guard let status = familyStatus else {
            errorMessage = "ファミリー状況が取得できません"
            return false
        }
        
        do {
            let response = try await api.removeFamilyMember(
                familyId: status.familyId,
                memberId: status.memberId
            )
            
            // ローカルからファミリー情報を削除
            UserDefaults.standard.removeObject(forKey: "userName")
            UserDefaults.standard.removeObject(forKey: "familyId")
            familyStatus = nil
            isFamilyIdSet = false
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to leave family: \(error)")
            return false
        }
    }
    
    // ファミリーメンバー一覧取得
    func fetchFamilyMembers() async {
        guard let status = familyStatus else {
            return
        }
        
        do {
            familyMembers = try await api.getFamilyMembers(familyId: status.familyId)
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to fetch family members: \(error)")
        }
    }
    
    // デバイストークンを更新
    func updateDeviceToken() async -> Bool {
        guard let status = familyStatus else {
            errorMessage = "ファミリー状況が取得できません"
            return false
        }
        
        guard SettingsManager.shared.hasDeviceToken() else {
            errorMessage = "デバイストークンが取得できていません"
            return false
        }
        
        do {
            let response = try await api.updateFamilyMember(
                familyId: status.familyId,
                memberId: status.memberId,
                name: status.name
            )
            
            print("デバイストークンの更新が完了しました")
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to update device token: \(error)")
            return false
        }
    }
    
    // 目標達成時にファミリーメンバーにプッシュ通知を送信
    func sendGoalAchievementNotification(goalTitle: String) async -> Bool {
        guard let status = familyStatus else {
            errorMessage = "ファミリー状況が取得できません"
            return false
        }
        
        do {
            let response = try await api.sendGoalAchievementNotification(
                familyId: status.familyId,
                memberId: status.memberId,
                memberName: status.name,
                goalTitle: goalTitle
            )
            
            print("目標達成通知の送信が完了しました")
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to send goal achievement notification: \(error)")
            return false
        }
    }
} 