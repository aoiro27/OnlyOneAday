import Foundation
import SwiftUI

// キャラクターの成長段階
enum CharacterStage: Int, CaseIterable {
    case egg = 0
    case baby = 1
    case child = 2
    case teenager = 3
    case adult = 4
    case master = 5
    
    var name: String {
        switch self {
        case .egg: return "卵"
        case .baby: return "赤ちゃん"
        case .child: return "子供"
        case .teenager: return "青年"
        case .adult: return "大人"
        case .master: return "マスター"
        }
    }
    
    var emoji: String {
        switch self {
        case .egg: return "🥚"
        case .baby: return "🐣"
        case .child: return "🐤"
        case .teenager: return "🐔"
        case .adult: return "🦅"
        case .master: return "🦅"
        }
    }
    
    var color: Color {
        switch self {
        case .egg: return .gray
        case .baby: return .orange
        case .child: return .yellow
        case .teenager: return .brown
        case .adult: return .blue
        case .master: return .purple
        }
    }
    
    var requiredCommits: Int {
        switch self {
        case .egg: return 0
        case .baby: return 10
        case .child: return 50
        case .teenager: return 100
        case .adult: return 200
        case .master: return 500
        }
    }
}

// キャラクターの状態
struct CharacterState {
    var stage: CharacterStage = .egg
    var totalCommits: Int = 0
    var consecutiveDays: Int = 0
    var lastCommitDate: Date?
    var daysWithoutCommit: Int = 0
    var maxConsecutiveDays: Int = 0
    
    // コミット数に基づいて成長段階を計算
    mutating func updateStage() {
        let newStage = CharacterStage.allCases.reversed().first { stage in
            totalCommits >= stage.requiredCommits
        } ?? .egg
        
        if newStage.rawValue > stage.rawValue {
            stage = newStage
        }
    }
    
    // コミットがない日数を更新
    mutating func updateDaysWithoutCommit() {
        guard let lastCommit = lastCommitDate else {
            daysWithoutCommit = 999 // 一度もコミットしていない場合
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let days = calendar.dateComponents([.day], from: lastCommit, to: today).day ?? 0
        daysWithoutCommit = max(0, days)
        
        // 一定期間コミットがないと退化
        if daysWithoutCommit >= 7 && stage != .egg {
            stage = CharacterStage(rawValue: max(0, stage.rawValue - 1)) ?? .egg
        }
    }
    
    // 新しいコミットを追加
    mutating func addCommits(_ count: Int, date: Date) {
        totalCommits += count
        
        if let lastCommit = lastCommitDate {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: lastCommit, to: date).day ?? 0
            
            if days == 1 {
                // 連続日数
                consecutiveDays += 1
                maxConsecutiveDays = max(maxConsecutiveDays, consecutiveDays)
            } else if days > 1 {
                // 連続が途切れた
                consecutiveDays = 1
            }
        } else {
            consecutiveDays = 1
            maxConsecutiveDays = 1
        }
        
        lastCommitDate = date
        daysWithoutCommit = 0
        
        updateStage()
    }
}

// キャラクター管理クラス
class CharacterManager: ObservableObject {
    @Published var character = CharacterState()
    private let settingsManager = SettingsManager.shared
    
    init() {
        loadCharacterState()
    }
    
    // キャラクター状態を更新
    func updateCharacter(with contributionData: ContributionCalendar?) {
        guard let data = contributionData else { return }
        
        var totalCommits = 0
        var lastCommitDate: Date?
        var commitDates: [Date] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 全期間のコミット数を集計し、コミットした日付を収集
        for week in data.weeks {
            for day in week.contributionDays {
                if day.contributionCount > 0 {
                    totalCommits += day.contributionCount
                    if let date = dateFormatter.date(from: day.date) {
                        commitDates.append(date)
                        if lastCommitDate == nil || date > lastCommitDate! {
                            lastCommitDate = date
                        }
                    }
                }
            }
        }
        
        // 連続コミット日数を計算
        let (consecutiveDays, maxConsecutiveDays) = calculateConsecutiveDays(from: commitDates)
        
        // キャラクター状態を更新
        character.totalCommits = totalCommits
        character.consecutiveDays = consecutiveDays
        character.maxConsecutiveDays = maxConsecutiveDays
        if let lastCommit = lastCommitDate {
            character.lastCommitDate = lastCommit
        }
        
        character.updateDaysWithoutCommit()
        character.updateStage()
        
        saveCharacterState()
    }
    
    // 連続コミット日数を計算
    private func calculateConsecutiveDays(from commitDates: [Date]) -> (consecutiveDays: Int, maxConsecutiveDays: Int) {
        guard !commitDates.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        let sortedDates = commitDates.sorted()
        
        var currentConsecutive = 1
        var maxConsecutive = 1
        var lastDate = sortedDates.first!
        
        for date in sortedDates.dropFirst() {
            let days = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0
            
            if days == 1 {
                // 連続日
                currentConsecutive += 1
                maxConsecutive = max(maxConsecutive, currentConsecutive)
            } else if days > 1 {
                // 連続が途切れた
                currentConsecutive = 1
            }
            // days == 0 の場合は同じ日なのでスキップ
            
            lastDate = date
        }
        
        // 現在の連続日数を計算（最新の日付から）
        let today = Date()
        let latestDate = sortedDates.last!
        let daysFromLatest = calendar.dateComponents([.day], from: latestDate, to: today).day ?? 0
        
        let currentConsecutiveDays: Int
        if daysFromLatest == 0 {
            // 今日コミットした場合
            currentConsecutiveDays = currentConsecutive
        } else if daysFromLatest == 1 {
            // 昨日コミットした場合
            currentConsecutiveDays = currentConsecutive
        } else {
            // 連続が途切れた
            currentConsecutiveDays = 0
        }
        
        return (currentConsecutiveDays, maxConsecutive)
    }
    
    // キャラクター状態を保存
    private func saveCharacterState() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(character.stage.rawValue, forKey: "character_stage")
        userDefaults.set(character.totalCommits, forKey: "character_total_commits")
        userDefaults.set(character.consecutiveDays, forKey: "character_consecutive_days")
        userDefaults.set(character.maxConsecutiveDays, forKey: "character_max_consecutive_days")
        userDefaults.set(character.lastCommitDate, forKey: "character_last_commit_date")
        userDefaults.set(character.daysWithoutCommit, forKey: "character_days_without_commit")
    }
    
    // キャラクター状態を読み込み
    private func loadCharacterState() {
        let userDefaults = UserDefaults.standard
        let stageRaw = userDefaults.integer(forKey: "character_stage")
        character.stage = CharacterStage(rawValue: stageRaw) ?? .egg
        character.totalCommits = userDefaults.integer(forKey: "character_total_commits")
        character.consecutiveDays = userDefaults.integer(forKey: "character_consecutive_days")
        character.maxConsecutiveDays = userDefaults.integer(forKey: "character_max_consecutive_days")
        character.lastCommitDate = userDefaults.object(forKey: "character_last_commit_date") as? Date
        character.daysWithoutCommit = userDefaults.integer(forKey: "character_days_without_commit")
    }
} 