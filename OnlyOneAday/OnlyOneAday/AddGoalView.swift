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
    let modelContext: ModelContext
    
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("目標の詳細")) {
                    TextField("目標のタイトル", text: $title)
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
            .navigationTitle("新しい目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addGoal()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addGoal() {
        let goal = Goal(title: title, goalDescription: "")
        modelContext.insert(goal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save goal: \(error)")
        }
    }
} 