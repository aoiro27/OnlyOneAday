//
//  AddFamilyGoalView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI

struct AddFamilyGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var familyGoalManager: FamilyGoalManager
    
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section() {
                    TextField("ミッション内容", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("ミッションの例")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 家族みんなで夕食を一緒に食べる")
                        Text("• お手伝いを3つ以上する")
                        Text("• 家族と30分以上話す")
                        Text("• 家族の誰かを褒める")
                        Text("• 家族と一緒にゲームをする")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("報酬: 肩叩き1分")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        
                        Text("ファミリーミッションを達成すると、肩叩き1分の報酬を獲得できます。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("ミッションを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        Task {
                            await addFamilyGoal()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || familyGoalManager.isLoading)
                }
            }
        }
    }
    
    private func addFamilyGoal() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let success = await familyGoalManager.createFamilyMission(mission: trimmedTitle)
        
        if success {
            // ファミリーミッション一覧を再取得
            await familyGoalManager.fetchFamilyMissions()
            dismiss()
        }
    }
}

#Preview {
    AddFamilyGoalView(familyGoalManager: FamilyGoalManager())
} 
