//
//  AddGoalView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userGoalManager: UserGoalManager
    
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section() {
                    TextField("ミッション内容", text: $title)
                }
                
                Section(header: Text("報酬について")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("全ての目標を達成すると報酬を獲得できます")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("報酬は目標一覧で設定できます")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
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
                            await addGoal()
                        }
                    }
                    .disabled(title.isEmpty || userGoalManager.isLoading)
                }
            }
        }
    }
    
    private func addGoal() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let success = await userGoalManager.createUserGoal(title: trimmedTitle)
        
        if success {
            dismiss()
        }
    }
}

#Preview {
    AddGoalView(userGoalManager: UserGoalManager())
}
