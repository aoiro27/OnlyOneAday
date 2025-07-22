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
    @Query private var familyGoals: [FamilyGoal]
    @State private var selectedTab = 0
    @State private var showingAddGoal = false
    @State private var lastResetDate: Date = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
    @State private var showingRewardAlert = false
    @State private var showingRewardSettings = false
    @State private var dailyRewards: [DailyReward] = []
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var completedFamilyGoals: [FamilyGoal] {
        familyGoals.filter { $0.isCompleted }
    }
    
    var allGoalsCompleted: Bool {
        !goals.isEmpty && goals.allSatisfy { $0.isCompleted }
    }
    
    var allFamilyGoalsCompleted: Bool {
        !familyGoals.isEmpty && familyGoals.allSatisfy { $0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // タブ選択
                Picker("目標タイプ", selection: $selectedTab) {
                    Text("個人目標").tag(0)
                    Text("ファミリー目標").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // 個人目標タブ
                    PersonalGoalsTabView(
                        goals: goals,
                        completedGoals: completedGoals,
                        allGoalsCompleted: allGoalsCompleted,
                        showingAddGoal: $showingAddGoal,
                        showingRewardAlert: $showingRewardAlert,
                        showingRewardSettings: $showingRewardSettings,
                        dailyRewards: $dailyRewards,
                        modelContext: modelContext
                    )
                } else {
                    // ファミリー目標タブ
                    FamilyGoalsTabView(
                        familyGoals: familyGoals,
                        completedFamilyGoals: completedFamilyGoals,
                        allFamilyGoalsCompleted: allFamilyGoalsCompleted,
                        showingAddGoal: $showingAddGoal,
                        showingRewardAlert: $showingRewardAlert,
                        modelContext: modelContext
                    )
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
                if selectedTab == 0 {
                    AddGoalView(modelContext: modelContext)
                } else {
                    AddFamilyGoalView()
                }
            }
            .sheet(isPresented: $showingRewardSettings) {
                RewardSettingsView(dailyRewards: $dailyRewards)
            }
            .alert("おめでとうございます！", isPresented: $showingRewardAlert) {
                Button("報酬を受け取る") {
                    claimAllRewards()
                }
            } message: {
                if dailyRewards.isEmpty {
                    Text("全ての目標を達成しました！\n\n今日一日お疲れさまでした。")
                } else {
                    let rewardText = dailyRewards.map { "• \($0.title) (\($0.minutes)分)" }.joined(separator: "\n")
                    Text("全ての目標を達成しました！\n\n報酬:\n\(rewardText)\n\n今日一日お疲れさまでした。")
                }
            }
        }
        .onAppear {
            loadDailyRewards()
            checkAndResetGoals()
        }
    }
    
    private func claimAllRewards() {
        // 既に報酬を受け取っているかチェック
        let hasAnyRewardClaimed = goals.contains { $0.isRewardClaimed }
        if hasAnyRewardClaimed {
            // 既に報酬を受け取っている場合は何もしない
            return
        }
        
        // 全ての目標に報酬を受け取ったマークを付ける
        for goal in goals {
            goal.claimReward()
        }
        
        // 各報酬を個別に作成
        for dailyReward in dailyRewards {
            let reward = Reward(
                title: dailyReward.title,
                rewardDescription: "全ての目標を達成して獲得した特別な報酬です。今日一日お疲れさまでした！",
                minutes: dailyReward.minutes,
                goalTitle: "全ての目標達成"
            )
            modelContext.insert(reward)
        }
        
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
        
        for goal in familyGoals {
            goal.reset()
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to reset goals: \(error)")
        }
    }
    
    private func loadDailyRewards() {
        let savedRewards = UserDefaults.standard.array(forKey: "dailyRewards") as? [[String: Any]] ?? []
        dailyRewards = savedRewards.compactMap {
            guard let title = $0["title"] as? String,
                  let minutes = $0["minutes"] as? Int else { return nil }
            return DailyReward(title: title, minutes: minutes)
        }
        
        // 初回起動時はデフォルトの報酬を設定
        if dailyRewards.isEmpty {
            dailyRewards = [
                DailyReward(title: "肩たたき券", minutes: 5),
                DailyReward(title: "ゲーム時間", minutes: 10)
            ]
            let encodedRewards = dailyRewards.map { [
                "title": $0.title,
                "minutes": $0.minutes
            ] }
            UserDefaults.standard.set(encodedRewards, forKey: "dailyRewards")
        }
    }
}

// 個人目標タブビュー
struct PersonalGoalsTabView: View {
    let goals: [Goal]
    let completedGoals: [Goal]
    let allGoalsCompleted: Bool
    @Binding var showingAddGoal: Bool
    @Binding var showingRewardAlert: Bool
    @Binding var showingRewardSettings: Bool
    @Binding var dailyRewards: [DailyReward]
    let modelContext: ModelContext
    
    var body: some View {
        VStack {
            if goals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("個人目標が設定されていません")
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
                        Text("個人目標を追加")
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
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("今日の報酬")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Button("変更") {
                                showingRewardSettings = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if dailyRewards.isEmpty {
                            Text("報酬が設定されていません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(dailyRewards) { reward in
                                HStack {
                                    Text("• \(reward.title) (\(reward.minutes)分)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
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
                        let hasAnyRewardClaimed = goals.contains { $0.isRewardClaimed }
                        
                        if hasAnyRewardClaimed {
                            // 既に報酬を受け取っている場合
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("今日の報酬を受け取りました！")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding()
                        } else {
                            // まだ報酬を受け取っていない場合
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
}

// ファミリー目標タブビュー
struct FamilyGoalsTabView: View {
    let familyGoals: [FamilyGoal]
    let completedFamilyGoals: [FamilyGoal]
    let allFamilyGoalsCompleted: Bool
    @Binding var showingAddGoal: Bool
    @Binding var showingRewardAlert: Bool
    let modelContext: ModelContext
    
    var body: some View {
        VStack {
            if familyGoals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("ファミリー目標が設定されていません")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("家族みんなで協力して達成できる目標を追加しましょう")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Text("ファミリー目標を追加")
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
                    FamilyGoalProgressView(completedGoals: completedFamilyGoals, totalGoals: familyGoals.count)
                    
                    // 報酬表示
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("ファミリー報酬")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.green)
                            Text("各目標達成で肩叩き1分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    List {
                        ForEach(familyGoals) { goal in
                            FamilyGoalRowView(goal: goal, modelContext: modelContext)
                                .swipeActions(edge: .trailing) {
                                    Button("削除", role: .destructive) {
                                        deleteGoal(goal)
                                    }
                                }
                        }
                        .onDelete(perform: deleteGoals)
                    }
                    

                }
            }
        }
    }
    
    private func deleteGoal(_ goal: FamilyGoal) {
        modelContext.delete(goal)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete family goal: \(error)")
        }
    }
    
    private func deleteGoals(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(familyGoals[index])
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete family goal: \(error)")
        }
    }
}

// 日次報酬の構造体
struct DailyReward: Identifiable, Codable {
    let id = UUID()
    var title: String
    var minutes: Int
    
    init(title: String, minutes: Int) {
        self.title = title
        self.minutes = minutes
    }
}

struct RewardSettingsView: View {
    @Binding var dailyRewards: [DailyReward]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("今日の報酬設定")) {
                    ForEach(Array(dailyRewards.enumerated()), id: \.element.id) { index, reward in
                        HStack {
                            TextField("報酬名", text: $dailyRewards[index].title)
                            Spacer()
                            Stepper(value: $dailyRewards[index].minutes, in: 0...480, step: 5) {
                                Text("\(dailyRewards[index].minutes)分")
                            }
                            
                            Button(action: {
                                dailyRewards.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button("報酬を追加") {
                        dailyRewards.append(DailyReward(title: "新しい報酬", minutes: 10))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("全ての目標を達成すると設定した報酬を獲得できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !dailyRewards.isEmpty {
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
                        let encodedRewards = dailyRewards.map { [
                            "title": $0.title,
                            "minutes": $0.minutes
                        ] }
                        UserDefaults.standard.set(encodedRewards, forKey: "dailyRewards")
                        dismiss()
                    }
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

struct FamilyGoalProgressView: View {
    let completedGoals: [FamilyGoal]
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
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
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

struct FamilyGoalRowView: View {
    let goal: FamilyGoal
    let modelContext: ModelContext
    @State private var showingRewardAlert = false
    
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
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            if !goal.isRewardClaimed {
                                Button(action: {
                                    showingRewardAlert = true
                                }) {
                                    Text("報酬")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange)
                                        .cornerRadius(8)
                                }
                            } else {
                                Text("完了")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .alert("おめでとうございます！", isPresented: $showingRewardAlert) {
            Button("肩叩き1分を受け取る") {
                claimReward()
            }
        } message: {
            Text("ファミリー目標「\(goal.title)」を達成しました！\n\n報酬: 肩叩き1分\n\n家族みんなで協力してくれてありがとう！")
        }
    }
    
    private func completeGoal() {
        goal.complete()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to complete family goal: \(error)")
        }
    }
    
    private func claimReward() {
        // 報酬を受け取ったマークを付ける
        goal.claimReward()
        
        // ファミリー報酬を作成
        let reward = Reward(
            title: "肩叩き券",
            rewardDescription: "ファミリー目標「\(goal.title)」を達成して獲得した報酬です。家族みんなで協力してくれてありがとう！",
            minutes: 1,
            goalTitle: goal.title
        )
        modelContext.insert(reward)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to claim family reward: \(error)")
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self], inMemory: true)
} 