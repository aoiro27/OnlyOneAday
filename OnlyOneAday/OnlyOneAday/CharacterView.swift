import SwiftUI

struct CharacterView: View {
    @ObservedObject var characterManager: CharacterManager
    
    var body: some View {
        VStack(spacing: 15) {
            // キャラクター表示
            VStack(spacing: 10) {
                Text(characterManager.character.stage.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.5), value: characterManager.character.stage)
                
                Text(characterManager.character.stage.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(characterManager.character.stage.color)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.1))
            )
            
            // ステータス情報
            VStack(spacing: 12) {
                StatusRow(
                    icon: "star.fill",
                    title: "総コミット数",
                    value: "\(characterManager.character.totalCommits)",
                    color: .yellow
                )
                
                StatusRow(
                    icon: "flame.fill",
                    title: "連続コミット",
                    value: "\(characterManager.character.consecutiveDays)日",
                    color: .orange
                )
                
                StatusRow(
                    icon: "trophy.fill",
                    title: "最高連続記録",
                    value: "\(characterManager.character.maxConsecutiveDays)日",
                    color: .purple
                )
                
                if characterManager.character.daysWithoutCommit > 0 {
                    StatusRow(
                        icon: "clock.fill",
                        title: "最後のコミットから",
                        value: "\(characterManager.character.daysWithoutCommit)日",
                        color: .red
                    )
                }
            }
            
            // 次の成長段階への進捗
            if let nextStage = getNextStage() {
                VStack(spacing: 8) {
                    Text("次の成長: \(nextStage.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: progressToNextStage(), total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: nextStage.color))
                        .frame(height: 8)
                    
                    Text("\(characterManager.character.totalCommits) / \(nextStage.requiredCommits)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // 警告メッセージ
            if characterManager.character.daysWithoutCommit >= 5 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(7 - characterManager.character.daysWithoutCommit)日で退化します！")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // 次の成長段階を取得
    private func getNextStage() -> CharacterStage? {
        let currentStage = characterManager.character.stage
        let nextStages = CharacterStage.allCases.filter { $0.rawValue > currentStage.rawValue }
        return nextStages.first
    }
    
    // 次の成長段階への進捗を計算
    private func progressToNextStage() -> Double {
        guard let nextStage = getNextStage() else { return 1.0 }
        
        let currentCommits = characterManager.character.totalCommits
        let currentStageCommits = characterManager.character.stage.requiredCommits
        let nextStageCommits = nextStage.requiredCommits
        
        let progress = Double(currentCommits - currentStageCommits) / Double(nextStageCommits - currentStageCommits)
        return max(0.0, min(1.0, progress))
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CharacterView(characterManager: CharacterManager())
} 