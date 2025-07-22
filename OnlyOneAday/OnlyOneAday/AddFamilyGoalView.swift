//
//  AddFamilyGoalView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData

struct AddFamilyGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var goalDescription = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ファミリー目標の詳細")) {
                    TextField("目標のタイトル", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("目標の説明（任意）", text: $goalDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section(header: Text("ファミリー目標の例")) {
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
                            Text("報酬: 肩叩き5分")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        
                        Text("全てのファミリー目標を達成すると、肩叩き5分の報酬を獲得できます。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("ファミリー目標を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addFamilyGoal()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addFamilyGoal() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let familyGoal = FamilyGoal(
            title: trimmedTitle,
            goalDescription: trimmedDescription
        )
        
        modelContext.insert(familyGoal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to add family goal: \(error)")
        }
    }
}

#Preview {
    AddFamilyGoalView()
        .modelContainer(for: [FamilyGoal.self], inMemory: true)
} 