//
//  FamilyGoal.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import Foundation
import SwiftData

@Model
final class FamilyGoal {
    var id: UUID
    var title: String
    var goalDescription: String
    var isCompleted: Bool
    var isRewardClaimed: Bool
    var createdAt: Date
    var completedAt: Date?
    var rewardClaimedAt: Date?
    
    init(title: String, goalDescription: String) {
        self.id = UUID()
        self.title = title
        self.goalDescription = goalDescription
        self.isCompleted = false
        self.isRewardClaimed = false
        self.createdAt = Date()
    }
    
    func complete() {
        self.isCompleted = true
        self.completedAt = Date()
    }
    
    func claimReward() {
        self.isRewardClaimed = true
        self.rewardClaimedAt = Date()
    }
    
    func reset() {
        self.isCompleted = false
        self.isRewardClaimed = false
        self.completedAt = nil
        self.rewardClaimedAt = nil
    }
} 