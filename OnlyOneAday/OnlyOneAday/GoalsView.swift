//
//  GoalsView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @State private var showingAddGoal = false
    @State private var lastResetDate: Date = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
    @State private var showingRewardAlert = false
    @State private var showingRewardSettings = false
    @State private var dailyReward: String = UserDefaults.standard.string(forKey: "dailyReward") ?? "肩たたき券"
    @State private var dailyRewardMinutes: Int = UserDefaults.standard.integer(forKey: "dailyRewardMinutes")
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var allGoalsCompleted: Bool {
        !goals.isEmpty && goals.allSatisfy { $0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if goals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("目標が設定されていません")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("新しい目標を追加して、毎日の学習を充実させましょう")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingAddGoal = true
                        }) {
                            Text("目標を追加")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        // 進捗表示
                        GoalProgressView(completedGoals: completedGoals, totalGoals: goals.count)
                        
                        // 報酬設定表示
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("今日の報酬: \(dailyReward) \(dailyRewardMinutes > 0 ? "(\(dailyRewardMinutes)分)" : "")")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Button("変更") {
                                showingRewardSettings = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        List {
                            ForEach(goals) { goal in
                                GoalRowView(goal: goal, modelContext: modelContext)
                                    .swipeActions(edge: .trailing) {
                                        Button("削除", role: .destructive) {
                                            deleteGoal(goal)
                                        }
                                    }
                            }
                            .onDelete(perform: deleteGoals)
                        }
                        
                        // 全て達成時の報酬ボタン
                        if allGoalsCompleted {
                            Button(action: {
                                showingRewardAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "gift.fill")
                                    Text("全ての目標達成！報酬を受け取る")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("毎日の目標")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(modelContext: modelContext)
            }
            .sheet(isPresented: $showingRewardSettings) {
                RewardSettingsView(dailyReward: $dailyReward, dailyRewardMinutes: $dailyRewardMinutes)
            }
            .alert("おめでとうございます！", isPresented: $showingRewardAlert) {
                Button("報酬を受け取る") {
                    claimAllRewards()
                }
            } message: {
                Text("全ての目標を達成しました！\n\n報酬: \(dailyReward) \(dailyRewardMinutes > 0 ? "(\(dailyRewardMinutes)分)" : "")\n\n今日一日お疲れさまでした。")
            }
        }
        .onAppear {
            checkAndResetGoals()
        }
    }
    
    private func deleteGoal(_ goal: Goal) {
        modelContext.delete(goal)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete goal: \(error)")
        }
    }
    
    private func deleteGoals(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(goals[index])
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete goal: \(error)")
        }
    }
    
    private func claimAllRewards() {
        // 全ての目標に報酬を受け取ったマークを付ける
        for goal in goals {
            goal.claimReward()
        }
        
        // 一つの報酬オブジェクトを作成
        let reward = Reward(
            title: dailyReward,
            rewardDescription: "全ての目標を達成して獲得した特別な報酬です。今日一日お疲れさまでした！",
            minutes: dailyRewardMinutes,
            goalTitle: "全ての目標達成"
        )
        modelContext.insert(reward)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to claim reward: \(error)")
        }
    }
    
    private func checkAndResetGoals() {
        let calendar = Calendar.current
        let today = Date()
        
        // 前回のリセット日と今日が同じ日かチェック
        if !calendar.isDate(lastResetDate, inSameDayAs: today) {
            resetAllGoals()
            lastResetDate = today
            UserDefaults.standard.set(lastResetDate, forKey: "lastResetDate")
        }
    }
    
    private func resetAllGoals() {
        for goal in goals {
            goal.reset()
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to reset goals: \(error)")
        }
    }
}

struct RewardSettingsView: View {
    @Binding var dailyReward: String
    @Binding var dailyRewardMinutes: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("今日の報酬設定")) {
                    TextField("例: 肩たたき券、ゲーム時間", text: $dailyReward)
                    
                    HStack {
                        Text("分数")
                        Spacer()
                        Stepper(value: $dailyRewardMinutes, in: 0...480, step: 5) {
                            Text("\(dailyRewardMinutes)分")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("全ての目標を達成すると設定した報酬を獲得できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if dailyRewardMinutes > 0 {
                            Text("例: ゲーム時間30分、肩たたき10分など")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("報酬設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        UserDefaults.standard.set(dailyReward, forKey: "dailyReward")
                        UserDefaults.standard.set(dailyRewardMinutes, forKey: "dailyRewardMinutes")
                        dismiss()
                    }
                    .disabled(dailyReward.isEmpty)
                }
            }
        }
    }
}

struct GoalProgressView: View {
    let completedGoals: [Goal]
    let totalGoals: Int
    
    var progress: Double {
        totalGoals > 0 ? Double(completedGoals.count) / Double(totalGoals) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("進捗")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(completedGoals.count)/\(totalGoals)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct GoalRowView: View {
    let goal: Goal
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                    
                    if !goal.goalDescription.isEmpty {
                        Text(goal.goalDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    if !goal.isCompleted {
                        Button(action: {
                            completeGoal()
                        }) {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func completeGoal() {
        goal.complete()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to complete goal: \(error)")
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self], inMemory: true)
} 