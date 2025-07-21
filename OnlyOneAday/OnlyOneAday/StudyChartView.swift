import SwiftUI
import Charts
import SwiftData

struct StudyChartView: View {
    @ObservedObject var studyManager: StudyManager
    @State private var selectedPeriod: ChartPeriod = .week
    
    enum ChartPeriod: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        
        var days: Int {
            switch self {
            case .week:
                return 7
            case .month:
                return 30
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 期間選択
            Picker("期間", selection: $selectedPeriod) {
                ForEach(ChartPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // グラフ
            Chart {
                ForEach(studyManager.getDailyStudyData(for: selectedPeriod.days)) { data in
                    LineMark(
                        x: .value("日付", data.dateString),
                        y: .value("学習時間", data.totalMinutes)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("日付", data.dateString),
                        y: .value("学習時間", data.totalMinutes)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1).gradient)
                    
                    PointMark(
                        x: .value("日付", data.dateString),
                        y: .value("学習時間", data.totalMinutes)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 2)
            
            // 統計情報
            StudyChartStatsView(studyManager: studyManager, period: selectedPeriod)
        }
        .padding()
    }
}

// グラフ統計情報ビュー
struct StudyChartStatsView: View {
    @ObservedObject var studyManager: StudyManager
    let period: StudyChartView.ChartPeriod
    
    var dailyData: [DailyStudyData] {
        studyManager.getDailyStudyData(for: period.days)
    }
    
    var totalStudyTime: Double {
        dailyData.reduce(0) { $0 + $1.totalMinutes }
    }
    
    var averageStudyTime: Double {
        let nonZeroDays = dailyData.filter { $0.totalMinutes > 0 }
        return nonZeroDays.isEmpty ? 0 : nonZeroDays.reduce(0) { $0 + $1.totalMinutes } / Double(nonZeroDays.count)
    }
    
    var maxStudyTime: Double {
        dailyData.map { $0.totalMinutes }.max() ?? 0
    }
    
    var studyDays: Int {
        dailyData.filter { $0.totalMinutes > 0 }.count
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("\(period.rawValue)統計")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                StatCard(
                    title: "総学習時間",
                    value: formatMinutes(totalStudyTime),
                    color: .blue
                )
                
                StatCard(
                    title: "平均学習時間",
                    value: formatMinutes(averageStudyTime),
                    color: .green
                )
                
                StatCard(
                    title: "最大学習時間",
                    value: formatMinutes(maxStudyTime),
                    color: .orange
                )
                
                StatCard(
                    title: "学習日数",
                    value: "\(studyDays)日",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)時間\(mins)分"
        } else {
            return "\(mins)分"
        }
    }
}

// 学習記録詳細ビュー（グラフ付き）
struct StudyDetailView: View {
    @ObservedObject var studyManager: StudyManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // グラフ
                    StudyChartView(studyManager: studyManager)
                    
                    // 日別詳細
                    DailyStudyDetailView(studyManager: studyManager)
                }
                .padding()
            }
            .navigationTitle("学習分析")
        }
    }
}

// 日別学習詳細ビュー
struct DailyStudyDetailView: View {
    @ObservedObject var studyManager: StudyManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("日別詳細")
                .font(.headline)
                .fontWeight(.bold)
            
            let dailyData = studyManager.getDailyStudyData(for: 7)
            
            if dailyData.isEmpty {
                Text("まだ学習記録がありません")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(dailyData.prefix(7)) { data in
                        DailyStudyCard(data: data)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// 日別学習カード
struct DailyStudyCard: View {
    let data: DailyStudyData
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: data.date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formatMinutes(data.totalMinutes))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                ForEach(data.sessions.sorted { $0.startTime > $1.startTime }) { session in
                    HStack {
                        Text(session.content)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(session.formattedDuration)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)時間\(mins)分"
        } else {
            return "\(mins)分"
        }
    }
}

#Preview {
    StudyChartView(studyManager: StudyManager(modelContext: ModelContext(try! ModelContainer(for: StudySession.self))))
} 