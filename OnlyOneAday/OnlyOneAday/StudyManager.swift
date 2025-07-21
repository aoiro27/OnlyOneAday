import Foundation
import SwiftData
import Combine

@MainActor
class StudyManager: ObservableObject {
    @Published var currentSession: StudySession?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isTimerRunning = false
    
    private var timer: Timer?
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // 学習セッションを開始
    func startSession(content: String) {
        let session = StudySession(content: content)
        currentSession = session
        modelContext.insert(session)
        
        startTimer()
    }
    
    // 学習セッションを停止
    func stopSession() {
        guard let session = currentSession else { return }
        
        session.endTime = Date()
        session.duration = elapsedTime
        
        stopTimer()
        currentSession = nil
        elapsedTime = 0
        
        try? modelContext.save()
    }
    
    // タイマーを開始
    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }
    
    // タイマーを停止
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    // フォーマットされた時間を取得
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // 日毎の学習時間データを取得
    func getDailyStudyData(for days: Int = 7) -> [DailyStudyData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate) ?? endDate
        
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.startTime >= startDate && session.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        // 日毎のデータを作成
        var result: [DailyStudyData] = []
        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
                
                let daySessions = sessions.filter { session in
                    session.startTime >= startOfDay && session.startTime < endOfDay
                }
                
                let totalMinutes = daySessions.reduce(0) { $0 + $1.duration / 60 }
                
                result.append(DailyStudyData(
                    date: date,
                    totalMinutes: totalMinutes,
                    sessions: daySessions
                ))
            }
        }
        
        // 日付順にソート
        return result.sorted { $0.date < $1.date }
    }
    
    // 今日の学習時間を取得
    func getTodayStudyTime() -> TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.startTime >= startOfDay && session.startTime < endOfDay
            }
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else {
            return 0
        }
        
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    // 今週の学習時間を取得
    func getThisWeekStudyTime() -> TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.startTime >= startOfWeek
            }
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else {
            return 0
        }
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    // 学習セッションを削除
    func deleteSession(_ session: StudySession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
} 
