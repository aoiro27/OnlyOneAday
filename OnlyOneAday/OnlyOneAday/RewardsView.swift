//
//  RewardsView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData

struct RewardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var rewards: [Reward]
    @State private var selectedRewardGroup: RewardGroup?
    @State private var useMinutes = 0
    
    // 同じ権利の分数を合算した未使用報酬
    var unusedRewardsGrouped: [RewardGroup] {
        let unused = rewards.filter { !$0.isUsed }
        let grouped = Dictionary(grouping: unused) { $0.title }
        return grouped.map { title, rewards in
            let totalMinutes = rewards.reduce(0) { $0 + $1.minutes }
            return RewardGroup(title: title, totalMinutes: totalMinutes, rewards: rewards)
        }.sorted { $0.rewards.first?.claimedAt ?? Date() > $1.rewards.first?.claimedAt ?? Date() }
    }
    
    // 使用済み報酬（個別表示）
    var usedRewards: [Reward] {
        rewards.filter { $0.isUsed }.sorted { $0.usedAt ?? $0.claimedAt > $1.usedAt ?? $1.claimedAt }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if rewards.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "gift")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("まだ報酬がありません")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("目標を達成して報酬を獲得しましょう")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        if !unusedRewardsGrouped.isEmpty {
                            Section("利用可能な報酬 (\(unusedRewardsGrouped.count)種類)") {
                                ForEach(unusedRewardsGrouped) { rewardGroup in
                                    UnusedRewardGroupView(
                                        rewardGroup: rewardGroup,
                                        onUse: {
                                            selectedRewardGroup = rewardGroup
                                            useMinutes = min(rewardGroup.totalMinutes, 30) // デフォルト30分または最大分数
                                        }
                                    )
                                }
                            }
                        }
                        
                        if !usedRewards.isEmpty {
                            Section("使用済み報酬 (\(usedRewards.count))") {
                                ForEach(usedRewards) { reward in
                                    UsedRewardRowView(reward: reward)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("報酬一覧")
            .sheet(item: $selectedRewardGroup) { rewardGroup in
                UseRewardSheet(
                    rewardGroup: rewardGroup,
                    useMinutes: $useMinutes,
                    onUse: {
                        useReward(rewardGroup, useMinutes: useMinutes)
                        selectedRewardGroup = nil
                    },
                    onCancel: {
                        selectedRewardGroup = nil
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func useReward(_ rewardGroup: RewardGroup, useMinutes: Int) {
        // 使用する分数に応じて報酬を消費
        var remainingMinutes = useMinutes
        let sortedRewards = rewardGroup.rewards.sorted { $0.claimedAt < $1.claimedAt } // 古い順
        
        for reward in sortedRewards {
            if remainingMinutes <= 0 { break }
            
            if reward.minutes <= remainingMinutes {
                // この報酬を完全に消費
                reward.use()
                remainingMinutes -= reward.minutes
            } else {
                // この報酬を部分的に消費（新しい報酬を作成）
                let usedReward = Reward(
                    title: reward.title,
                    rewardDescription: reward.rewardDescription,
                    minutes: remainingMinutes,
                    goalTitle: reward.goalTitle
                )
                usedReward.claimedAt = reward.claimedAt
                usedReward.use()
                modelContext.insert(usedReward)
                
                // 元の報酬の分数を減らす
                reward.minutes -= remainingMinutes
                remainingMinutes = 0
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to use reward: \(error)")
        }
    }
}

struct UseRewardSheet: View {
    let rewardGroup: RewardGroup
    @Binding var useMinutes: Int
    let onUse: () -> Void
    let onCancel: () -> Void
    
    var remainingMinutes: Int {
        rewardGroup.totalMinutes - useMinutes
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 報酬情報表示
                VStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text(rewardGroup.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("利用可能: \(rewardGroup.totalMinutes)分")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("獲得回数: \(rewardGroup.rewards.count)回")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // 分数選択
                VStack(spacing: 16) {
                    Text("使用する分数を選択")
                        .font(.headline)
                    
                    HStack {
                        Text("分数")
                            .font(.body)
                        
                        Spacer()
                        
                        Stepper(value: $useMinutes, in: 5...rewardGroup.totalMinutes, step: 5) {
                            Text("\(useMinutes)分")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 残り分数表示
                    if remainingMinutes > 0 {
                        Text("使用後残り: \(remainingMinutes)分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("全て使用します")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // 使用ボタン
                Button(action: onUse) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("\(useMinutes)分使用する")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(useMinutes <= 0)
            }
            .navigationTitle("報酬を使用")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// 報酬グループ（同じ権利の合算）
struct RewardGroup: Identifiable {
    let id = UUID()
    let title: String
    let totalMinutes: Int
    let rewards: [Reward]
}

struct UnusedRewardGroupView: View {
    let rewardGroup: RewardGroup
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rewardGroup.title)
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("\(rewardGroup.totalMinutes)分")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("獲得回数: \(rewardGroup.rewards.count)回")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("最新獲得: \(formatDate(rewardGroup.rewards.first?.claimedAt ?? Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onUse) {
                    Text("使用")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct UsedRewardRowView: View {
    let reward: Reward
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("\(reward.minutes)分")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                        Text("目標: \(reward.goalTitle)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let usedAt = reward.usedAt {
                        Text("使用日: \(formatDate(usedAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    RewardsView()
        .modelContainer(for: [Reward.self], inMemory: true)
} 