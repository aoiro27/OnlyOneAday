import Foundation
import SwiftData

@Model
class StudySession {
    var id: UUID
    var content: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var createdAt: Date
    
    init(content: String, startTime: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.startTime = startTime
        self.endTime = nil
        self.duration = 0
        self.createdAt = Date()
    }
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startTime)
    }
}

// 日毎の学習時間データ
struct DailyStudyData: Identifiable {
    let id = UUID()
    let date: Date
    let totalMinutes: Double
    let sessions: [StudySession]
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
} 