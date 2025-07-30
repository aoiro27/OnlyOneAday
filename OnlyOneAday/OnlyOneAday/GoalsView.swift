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
    @StateObject private var userGoalManager = UserGoalManager()
    @EnvironmentObject var familyGoalManager: FamilyGoalManager
    @State private var selectedTab = 0
    @State private var showingAddGoal = false
    @State private var lastResetDate: Date = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
    @State private var showingRewardAlert = false
    @State private var showingRewardSettings = false
    @State private var dailyRewards: [DailyReward] = []
    
    var completedGoals: [UserGoalInfo] {
        userGoalManager.completedGoals
    }
    
    var completedFamilyGoals: [FamilyMissionResponse] {
        familyGoalManager.completedMissions
    }
    
    var allGoalsCompleted: Bool {
        !userGoalManager.userGoals.isEmpty && userGoalManager.userGoals.allSatisfy { $0.isCompleted }
    }
    
    var allFamilyGoalsCompleted: Bool {
        familyGoalManager.allMissionsCompleted
    }
    
    // 今日既に報酬を受け取ったかどうかをチェック
    var hasTodayRewardClaimed: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let lastClaimDate = UserDefaults.standard.object(forKey: "lastPersonalRewardClaimDate") as? Date
        
        if let lastClaimDate = lastClaimDate {
            return Calendar.current.isDate(lastClaimDate, inSameDayAs: today)
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // タブ選択
                Picker("ミッションタイプ", selection: $selectedTab) {
                    Text("個人ミッション").tag(0)
                    Text("ファミリーミッション").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // 個人目標タブ
                    PersonalGoalsTabView(
                        userGoalManager: userGoalManager,
                        completedGoals: completedGoals,
                        allGoalsCompleted: allGoalsCompleted,
                        hasTodayRewardClaimed: hasTodayRewardClaimed,
                        showingAddGoal: $showingAddGoal,
                        showingRewardAlert: $showingRewardAlert,
                        showingRewardSettings: $showingRewardSettings,
                        dailyRewards: $dailyRewards,
                        modelContext: modelContext
                    )
                    .environmentObject(familyGoalManager)
                } else {
                    // ファミリー目標タブ
                    if familyGoalManager.isFamilyIdSet {
                        FamilyGoalsTabView(
                            familyGoalManager: familyGoalManager,
                            completedFamilyGoals: completedFamilyGoals,
                            allFamilyGoalsCompleted: allFamilyGoalsCompleted,
                            showingAddGoal: $showingAddGoal,
                            showingRewardAlert: $showingRewardAlert
                        )
                    } else {
                        FamilyIdNotSetView()
                    }
                }
            }
            .navigationTitle("デイリーミッション")
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
                    AddGoalView(userGoalManager: userGoalManager)
                } else {
                    AddFamilyGoalView(familyGoalManager: familyGoalManager)
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
            // 個人目標はクラウド管理のため、リセット機能は不要
            familyGoalManager.checkLocalFamilyId()
            if familyGoalManager.isFamilyIdSet {
                Task {
                    await familyGoalManager.fetchFamilyStatus()
                    await familyGoalManager.fetchFamilyMissions()
                }
            }
        }
    }
    
    private func claimAllRewards() {
        // 今日の報酬を受け取った日付を保存
        UserDefaults.standard.set(Date(), forKey: "lastPersonalRewardClaimDate")
        
        // 各報酬を個別に作成
        for dailyReward in dailyRewards {
            let reward = Reward(
                title: dailyReward.title,
                rewardDescription: "全てのミッションを達成して獲得した特別な報酬です。今日一日お疲れさまでした！",
                minutes: dailyReward.minutes,
                goalTitle: "全てのミッション達成"
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
        // 個人目標はクラウド管理のため、リセット機能は不要
        // TODO: 必要に応じてAPI経由でリセット機能を実装
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
    @ObservedObject var userGoalManager: UserGoalManager
    let completedGoals: [UserGoalInfo]
    let allGoalsCompleted: Bool
    let hasTodayRewardClaimed: Bool
    @Binding var showingAddGoal: Bool
    @Binding var showingRewardAlert: Bool
    @Binding var showingRewardSettings: Bool
    @Binding var dailyRewards: [DailyReward]
    let modelContext: ModelContext
    @EnvironmentObject var familyGoalManager: FamilyGoalManager
    
    var body: some View {
        VStack {
            if userGoalManager.isLoading {
                // ローディング表示
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("目標を読み込み中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if userGoalManager.userGoals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("個人ミッションが設定されていません")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("新しいミッションを追加して、毎日の成長しましょう")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Text("ミッション追加")
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
                    GoalProgressView(completedGoals: completedGoals, totalGoals: userGoalManager.userGoals.count)
                    
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
                        ForEach(userGoalManager.userGoals, id: \.goalId) { goal in
                            UserGoalRowView(goal: goal, userGoalManager: userGoalManager, familyGoalManager: familyGoalManager)
                                .swipeActions(edge: .trailing) {
                                    Button("削除", role: .destructive) {
                                        Task {
                                            await deleteGoal(goal)
                                        }
                                    }
                                }
                        }
                    }
                    
                    // 全て達成時の報酬ボタン
                    if allGoalsCompleted {
                        if hasTodayRewardClaimed {
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
                                    Text("全てのミッション達成！報酬を受け取る")
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
    
    private func deleteGoal(_ goal: UserGoalInfo) async {
        let success = await userGoalManager.deleteUserGoal(goalId: goal.goalId)
        
        if !success {
            print("Failed to delete user goal")
        }
    }
}

// ファミリー目標タブビュー
struct FamilyGoalsTabView: View {
    @ObservedObject var familyGoalManager: FamilyGoalManager
    let completedFamilyGoals: [FamilyMissionResponse]
    let allFamilyGoalsCompleted: Bool
    @Binding var showingAddGoal: Bool
    @Binding var showingRewardAlert: Bool
    
    var body: some View {
        VStack {
            if familyGoalManager.isLoading {
                // ローディング表示
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("ファミリーミッションを読み込み中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if familyGoalManager.familyMissions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("ファミリーミッションが設定されていません")
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
                        Text("ファミリーミッションを追加")
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
                    FamilyGoalProgressView(completedGoals: completedFamilyGoals, totalGoals: familyGoalManager.familyMissions.count)
                    
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
                        ForEach(familyGoalManager.familyMissions, id: \.docId) { mission in
                            FamilyMissionRowView(mission: mission, familyGoalManager: familyGoalManager)
                                .swipeActions(edge: .trailing) {
                                    Button("削除", role: .destructive) {
                                        Task {
                                            await deleteMission(mission)
                                        }
                                    }
                                }
                        }
                    }
                    
                    
                }
            }
        }
    }
    
    private func deleteMission(_ mission: FamilyMissionResponse) async {
        let success = await familyGoalManager.deleteFamilyMission(docId: mission.docId)
        
        if !success {
            print("Failed to delete family mission")
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
                        Text("全てのミッションを達成すると設定した報酬を獲得できます")
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
    let completedGoals: [UserGoalInfo]
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
    let completedGoals: [FamilyMissionResponse]
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
    @EnvironmentObject var familyGoalManager: FamilyGoalManager
    
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
                            Task {
                                await completeGoal()
                            }
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
    
    private func completeGoal() async {
        goal.complete()
        
        do {
            try modelContext.save()
            
            // ファミリーに参加している場合はプッシュ通知を送信
            if familyGoalManager.isFamilyIdSet {
                await familyGoalManager.sendGoalAchievementNotification(goalTitle: goal.title)
            }
        } catch {
            print("Failed to complete goal: \(error)")
        }
    }
}

// 個人目標行ビュー
struct UserGoalRowView: View {
    let goal: UserGoalInfo
    @ObservedObject var userGoalManager: UserGoalManager
    @ObservedObject var familyGoalManager: FamilyGoalManager
    @Environment(\.modelContext) private var modelContext
    @State private var showingRewardAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    if !goal.isCompleted {
                        Button(action: {
                            Task {
                                await completeGoal()
                            }
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
                            
                            Text("完了")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .alert("おめでとうございます！", isPresented: $showingRewardAlert) {
            Button("OK") { }
        } message: {
            Text("個人目標「\(goal.title)」を達成しました！\n\n今日一日お疲れさまでした！")
        }
    }
    
    private func completeGoal() async {
        let success = await userGoalManager.completeUserGoal(goalId: goal.goalId)
        
        if success {
            
            // 目標達成記録を作成して保存
            let achievementRecord = GoalAchievementRecord(
                goalId: goal.goalId,
                title: goal.title,
                achievedDate: Date(),
                isCompleted: true
            )
            modelContext.insert(achievementRecord)
            
            do {
                try modelContext.save()
                let fetchDescriptor = FetchDescriptor<GoalAchievementRecord>()
                   if let savedRecords = try? modelContext.fetch(fetchDescriptor) {
                       print("🎯 Saved GoalAchievementRecords in SwiftData:")
                       for record in savedRecords {
                           print("   - goalId: \(record.goalId)")
                           print("   - title: \(record.title)")
                           print("   - achievedDate: \(record.achievedDate)")
                           print("   - isCompleted: \(record.isCompleted)")
                           print("   ---")
                       }
                   }
            } catch {
                print("Failed to save achievement record: \(error)")
            }
            
            // ファミリーに参加している場合はプッシュ通知を送信
            if familyGoalManager.isFamilyIdSet {
                await familyGoalManager.sendGoalAchievementNotification(goalTitle: goal.title)
            }
            showingRewardAlert = true
        } else {
            print("Failed to complete user goal")
        }
    }
}

struct FamilyMissionRowView: View {
    let mission: FamilyMissionResponse
    @ObservedObject var familyGoalManager: FamilyGoalManager
    @Environment(\.modelContext) private var modelContext
    @State private var showingRewardAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.mission)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    if !mission.isCleared {
                        Button(action: {
                            Task {
                                await completeMission()
                            }
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
                            
                            Text("完了")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .alert("おめでとうございます！", isPresented: $showingRewardAlert) {
            Button("OK") { }
        } message: {
            Text("ファミリー目標「\(mission.mission)」を達成しました！\n\n報酬: 肩叩き1分\n\n家族みんなで協力してくれてありがとう！")
        }
    }
    
    private func completeMission() async {
        let success = await familyGoalManager.updateFamilyMission(
            docId: mission.docId,
            mission: mission.mission,
            isCleared: true
        )
        
        if success {
            
            // 目標達成記録を作成して保存
            let achievementRecord = FamilyGoalAchievementRecord(
                goalId: mission.docId,
                title: mission.mission,
                achievedDate: Date(),
                isCompleted: true
            )
            modelContext.insert(achievementRecord)
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to save achievement record: \(error)")
            }
            
            // 報酬を自動的に付与
            claimReward()
            showingRewardAlert = true
            
            // ファミリーメンバーにプッシュ通知を送信
            await familyGoalManager.sendGoalAchievementNotification(goalTitle: mission.mission)
        } else {
            print("Failed to complete family mission")
        }
    }
    
    private func claimReward() {
        // 既に同じ目標の報酬が存在するかチェック
        let existingRewards = try? modelContext.fetch(FetchDescriptor<Reward>())
        let hasExistingReward = existingRewards?.contains { $0.goalTitle == mission.mission } ?? false
        
        if hasExistingReward {
            print("Reward already claimed for mission: \(mission.mission)")
            return
        }
        
        // ファミリー報酬を作成
        let reward = Reward(
            title: "肩叩き券",
            rewardDescription: "ファミリー目標「\(mission.mission)」を達成して獲得した報酬です。家族みんなで協力してくれてありがとう！",
            minutes: 1,
            goalTitle: mission.mission
        )
        
        modelContext.insert(reward)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to claim family reward: \(error)")
        }
    }
}

// ファミリーID未設定時のビュー
struct FamilyIdNotSetView: View {
    @State private var showingFamilyManagement = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("ファミリー設定が完了していません")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("ファミリー目標を使用するには、ファミリーを作成するか既存のファミリーに参加してください。")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingFamilyManagement = true
            }) {
                Text("ファミリー管理")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $showingFamilyManagement) {
            FamilyManagementView()
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self], inMemory: true)
}
