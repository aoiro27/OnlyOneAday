import SwiftUI
import AVKit

struct CharacterDetailView: View {
    let stage: Int
    @Environment(\.dismiss) private var dismiss
    
    var videoFileName: String { "character_stage\(stage)" }
    var thumbnailFileName: String { "character_stage\(stage)" }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // サムネイル画像
                    Image(thumbnailFileName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                    
                    // 成長段階表示
                    VStack(spacing: 8) {
                        Text("成長段階 \(stage)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text(getStageDescription(stage))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // mp4動画（自動再生・UI非表示）
                    VStack(spacing: 12) {
                        Text("キャラクター動画")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if let url = Bundle.main.url(forResource: videoFileName, withExtension: "mp4") {
                            AutoPlayVideoView(url: url)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "video.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                
                                Text("動画ファイルが見つかりません")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("\(videoFileName).mp4 をプロジェクトに追加してください")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // キャラクター説明
                    VStack(spacing: 12) {
                        Text("キャラクターについて")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text(getCharacterDescription(stage))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("キャラクター詳細")
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
    
    // 成長段階の説明を取得
    private func getStageDescription(_ stage: Int) -> String {
        switch stage {
        case 1:
            return "初心者レベル\nコントリビューションを始めたばかり"
        case 2:
            return "成長期\n少しずつコントリビューションが増えてきた"
        case 3:
            return "中級者\n安定してコントリビューションできている"
        case 4:
            return "上級者\n多くのコントリビューションを達成"
        case 5:
            return "マスター\nコントリビューションの達人"
        default:
            return "未知の成長段階"
        }
    }
    
    // キャラクターの詳細説明を取得
    private func getCharacterDescription(_ stage: Int) -> String {
        switch stage {
        case 1:
            return "あなたのキャラクターはまだ初心者です。毎日少しずつでもコントリビューションを続けることで、確実に成長していきます。小さな一歩から始めましょう！"
        case 2:
            return "成長期に入ったキャラクターです。コントリビューションの習慣が身についてきています。継続は力なり、この調子で頑張りましょう！"
        case 3:
            return "中級者レベルのキャラクターです。安定してコントリビューションできており、開発者としての実力が認められています。さらに高みを目指しましょう！"
        case 4:
            return "上級者レベルのキャラクターです。多くのコントリビューションを達成し、開発コミュニティに大きく貢献しています。あなたの技術力は素晴らしいです！"
        case 5:
            return "マスタークラスのキャラクターです。コントリビューションの達人として、開発コミュニティのリーダー的存在です。あなたの経験と技術は多くの人々の目標となっています！"
        default:
            return "このキャラクターについての詳細情報は準備中です。"
        }
    }
}

#Preview {
    CharacterDetailView(stage: 1)
} 