import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var studySessions: [StudySession]
    @State private var studyManager: StudyManager?
    @State private var studyContent = ""
    @State private var showingSessionList = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // タブ選択
                Picker("タブ", selection: $selectedTab) {
                    Text("学習記録").tag(0)
                    Text("学習分析").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // 学習記録タブ
                    StudyRecordTabView(
                        studyManager: studyManager,
                        studyContent: $studyContent,
                        showingSessionList: $showingSessionList,
                        studySessions: studySessions
                    )
                } else {
                    // 学習分析タブ
                    if let manager = studyManager {
                        StudyDetailView(studyManager: manager)
                    } else {
                        ProgressView("読み込み中...")
                    }
                }
            }
            .navigationTitle("学習管理")
            .sheet(isPresented: $showingSessionList) {
                if let manager = studyManager {
                    StudySessionListView(sessions: studySessions, studyManager: manager)
                }
            }
        }
        .onAppear {
            if studyManager == nil {
                studyManager = StudyManager(modelContext: modelContext)
            }
        }
    }
}

// 学習記録タブビュー
struct StudyRecordTabView: View {
    let studyManager: StudyManager?
    @Binding var studyContent: String
    @Binding var showingSessionList: Bool
    let studySessions: [StudySession]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let manager = studyManager {
                    // 統計情報
                    StatisticsView(studyManager: manager)
                    
                    // 学習セッション管理
                    StudySessionView(
                        studyManager: manager,
                        studyContent: $studyContent
                    )
                    
                    // 最近の学習セッション
                    RecentSessionsView(sessions: studySessions)
                } else {
                    ProgressView("読み込み中...")
                }
                
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("履歴") {
                    showingSessionList = true
                }
            }
        }
    }
}

// 統計情報ビュー
struct StatisticsView: View {
    @ObservedObject var studyManager: StudyManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("学習統計")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "今日",
                    value: formatTime(studyManager.getTodayStudyTime()),
                    color: .blue
                )
                
                StatCard(
                    title: "今週",
                    value: formatTime(studyManager.getThisWeekStudyTime()),
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// 統計カード
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// 学習セッション管理ビュー
struct StudySessionView: View {
    @ObservedObject var studyManager: StudyManager
    @Binding var studyContent: String
    
    var body: some View {
        VStack(spacing: 15) {
            Text("学習セッション")
                .font(.headline)
                .fontWeight(.bold)
            
            if studyManager.currentSession == nil {
                // セッション開始フォーム
                VStack(spacing: 15) {
                    TextField("学習内容を入力してください", text: $studyContent, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    Button("学習開始") {
                        if !studyContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            studyManager.startSession(content: studyContent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(studyContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                // アクティブなセッション
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("学習中")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(studyManager.currentSession?.content ?? "")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // タイマー表示
                    Text(studyManager.formattedElapsedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Button("学習終了") {
                        studyManager.stopSession()
                        studyContent = ""
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// 最近の学習セッション
struct RecentSessionsView: View {
    let sessions: [StudySession]
    
    var recentSessions: [StudySession] {
        Array(sessions.sorted { $0.startTime > $1.startTime }.prefix(5))
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("最近の学習")
                .font(.headline)
                .fontWeight(.bold)
            
            if recentSessions.isEmpty {
                Text("まだ学習記録がありません")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(recentSessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.content)
                                    .font(.body)
                                    .lineLimit(2)
                                
                                Text(formatDate(session.startTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(session.formattedDuration)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// 学習セッション履歴ビュー
struct StudySessionListView: View {
    let sessions: [StudySession]
    @ObservedObject var studyManager: StudyManager
    @Environment(\.dismiss) private var dismiss
    
    var sortedSessions: [StudySession] {
        sessions.sorted { $0.startTime > $1.startTime }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedSessions) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.content)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(formatDate(session.startTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(session.formattedDuration)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        if let endTime = session.endTime {
                            Text("終了: \(formatDate(endTime))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button("削除", role: .destructive) {
                            studyManager.deleteSession(session)
                        }
                    }
                }
            }
            .navigationTitle("学習履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    StudyView()
        .modelContainer(for: [StudySession.self], inMemory: true)
} 