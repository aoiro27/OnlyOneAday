//
//  Reward.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import Foundation
import SwiftData

@Model
final class Reward {
    var id: UUID
    var title: String
    var rewardDescription: String
    var minutes: Int // 分数を追加
    var isUsed: Bool
    var claimedAt: Date
    var usedAt: Date?
    var goalTitle: String // どの目標から獲得したかを記録
    
    init(title: String, rewardDescription: String, minutes: Int, goalTitle: String) {
        self.id = UUID()
        self.title = title
        self.rewardDescription = rewardDescription
        self.minutes = minutes
        self.isUsed = false
        self.claimedAt = Date()
        self.goalTitle = goalTitle
    }
    
    func use() {
        self.isUsed = true
        self.usedAt = Date()
    }
} 