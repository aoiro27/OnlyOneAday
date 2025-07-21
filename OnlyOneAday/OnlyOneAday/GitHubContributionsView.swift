import SwiftUI

struct GitHubContributionsView: View {
    @StateObject private var graphQLClient = GitHubGraphQLClient()
    @StateObject private var settingsManager = SettingsManager.shared
    @Binding var selectedTab: Int
    @State private var currentDate = Date()
    @State private var showingDatePicker = false
    
    // カレンダー関連の計算プロパティ
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: currentDate)
    }
    
    private var calendarDays: [CalendarDay] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        let endOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.end ?? currentDate
        
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: endOfMonth)?.end ?? endOfMonth
        
        var days: [CalendarDay] = []
        var currentDate = startOfWeek
        
        while currentDate < endOfWeek {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: startOfMonth, toGranularity: .month)
            let dayNumber = calendar.component(.day, from: currentDate)
            let weekday = calendar.component(.weekday, from: currentDate)
            
            days.append(CalendarDay(
                date: currentDate,
                dayNumber: dayNumber,
                isCurrentMonth: isCurrentMonth,
                weekday: weekday
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    // 月の切り替えメソッド
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    

    
    var body: some View {
        NavigationView {
            Group {
                if !settingsManager.hasGitHubToken() {
                    // 設定が必要な場合の表示
                    VStack(spacing: 30) {
                        Image(systemName: "gear.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 15) {
                            Text("設定が必要です")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("GitHubのコントリビューション情報を表示するには、設定タブでPersonal Access Tokenを設定してください。")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                        
                        Button("設定を開く") {
                            selectedTab = 1 // 設定タブに移動
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                } else if settingsManager.defaultGitHubUsername.isEmpty {
                    // ユーザー名が設定されていない場合
                    VStack(spacing: 30) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 15) {
                            Text("ユーザー名を設定してください")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("設定タブでデフォルトのGitHubユーザー名を設定してください。")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                        
                        Button("設定を開く") {
                            selectedTab = 1 // 設定タブに移動
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                } else {
                    // コントリビューション情報を表示
                    VStack(spacing: 20) {
                        // ヘッダー
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("GitHub Contributions")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(settingsManager.defaultGitHubUsername)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // エラーメッセージ
                        if let errorMessage = graphQLClient.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal, 20)
                        }
                        
                        // コントリビューション情報
                        if let contributionData = graphQLClient.contributionData {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    // 総コントリビューション数
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("総コントリビューション数")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("\(contributionData.totalContributions)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    
                                    // カレンダー表示
                                    VStack(alignment: .leading, spacing: 15) {
                                        // 月ヘッダー
                                        HStack {
                                            Button(action: previousMonth) {
                                                Image(systemName: "chevron.left")
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: { showingDatePicker = true }) {
                                                Text(monthYearString)
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: nextMonth) {
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        // 曜日ヘッダー
                                        HStack(spacing: 0) {
                                            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { dayOfWeek in
                                                Text(dayOfWeek)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        // カレンダーグリッド
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                                            ForEach(calendarDays, id: \.self) { day in
                                                CalendarDayView(day: day, contributionData: contributionData)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .sheet(isPresented: $showingDatePicker) {
                                        DatePickerView(selectedDate: $currentDate)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("GitHub Contributions")
        .onAppear {
            // 設定が完了している場合は自動的にコントリビューションを取得
            if settingsManager.hasGitHubToken() && !settingsManager.defaultGitHubUsername.isEmpty {
                Task {
                    await graphQLClient.fetchUserContributions(userName: settingsManager.defaultGitHubUsername)
                }
            }
        }
        .onChange(of: settingsManager.githubAccessToken) { _, _ in
            // トークンが変更された場合、ユーザー名も設定されていれば再取得
            if settingsManager.hasGitHubToken() && !settingsManager.defaultGitHubUsername.isEmpty {
                Task {
                    await graphQLClient.fetchUserContributions(userName: settingsManager.defaultGitHubUsername)
                }
            }
        }
        .onChange(of: settingsManager.defaultGitHubUsername) { _, _ in
            // ユーザー名が変更された場合、トークンも設定されていれば再取得
            if settingsManager.hasGitHubToken() && !settingsManager.defaultGitHubUsername.isEmpty {
                Task {
                    await graphQLClient.fetchUserContributions(userName: settingsManager.defaultGitHubUsername)
                }
            }
        }
    }
}





// カレンダー日付構造体
struct CalendarDay: Hashable {
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
    let weekday: Int
}

// カレンダー日付ビュー
struct CalendarDayView: View {
    let day: CalendarDay
    let contributionData: ContributionCalendar
    
    private var contributionCount: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: day.date)
        
        for week in contributionData.weeks {
            for contributionDay in week.contributionDays {
                if contributionDay.date == dateString {
                    return contributionDay.contributionCount
                }
            }
        }
        return 0
    }
    
    private var color: Color {
        switch contributionCount {
        case 0:
            return Color.gray.opacity(0.1)
        case 1...3:
            return Color.green.opacity(0.3)
        case 4...6:
            return Color.green.opacity(0.5)
        case 7...9:
            return Color.green.opacity(0.7)
        case 10...19:
            return Color.green.opacity(0.8)
        default:
            return Color.green
        }
    }
    
    var body: some View {
        VStack(spacing: 1) {
            Text("\(day.dayNumber)")
                .font(.caption2)
                .foregroundColor(day.isCurrentMonth ? .primary : .secondary)
                .frame(height: 16)
            
            if contributionCount > 0 {
                Text("\(contributionCount)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 12)
                    .background(color)
                    .cornerRadius(2)
            } else {
                Text("0")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 12)
            }
        }
        .frame(height: 40)
    }
}

// 日付選択ビュー
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "月を選択",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .navigationTitle("月を選択")
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
}

#Preview {
    GitHubContributionsView(selectedTab: .constant(0))
} 