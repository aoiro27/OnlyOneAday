//
//  CategoryManagementView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @ObservedObject var studyManager: StudyManager
    @Environment(\.dismiss) private var dismiss
    @State private var newCategoryName = ""
    @State private var selectedColor = "blue"
    @State private var showingAddCategory = false
    @State private var editingCategory: StudyCategory? = nil
    @State private var showingEditCategory = false
    
    let colors = [
        ("blue", Color.blue),
        ("green", Color.green),
        ("orange", Color.orange),
        ("purple", Color.purple),
        ("red", Color.red),
        ("pink", Color.pink),
        ("indigo", Color.indigo),
        ("teal", Color.teal)
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section("カテゴリ一覧") {
                    ForEach(studyManager.getCategories()) { category in
                        HStack {
                            Circle()
                                .fill(colorForString(category.color))
                                .frame(width: 20, height: 20)
                            Text(category.name)
                                .font(.body)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                            showingEditCategory = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button("削除", role: .destructive) {
                                studyManager.deleteCategory(category)
                            }
                        }
                    }
                }
            }
            .navigationTitle("カテゴリ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        showingAddCategory = true
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(studyManager: studyManager)
            }
            .sheet(isPresented: $showingEditCategory) {
                if let editingCategory = editingCategory {
                    EditCategoryView(studyManager: studyManager, category: editingCategory, isPresented: $showingEditCategory)
                }
            }
        }
    }
    
    private func colorForString(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .blue
        }
    }
}

struct AddCategoryView: View {
    @ObservedObject var studyManager: StudyManager
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName = ""
    @State private var selectedColor = "blue"
    
    let colors = [
        ("blue", Color.blue),
        ("green", Color.green),
        ("orange", Color.orange),
        ("purple", Color.purple),
        ("red", Color.red),
        ("pink", Color.pink),
        ("indigo", Color.indigo),
        ("teal", Color.teal)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("カテゴリ名") {
                    TextField("カテゴリ名を入力", text: $categoryName)
                }
                
                Section("色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(colors, id: \.0) { colorName, color in
                            Button(action: {
                                selectedColor = colorName
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == colorName ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("カテゴリ追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        if !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            studyManager.addCategory(name: categoryName, color: selectedColor)
                            dismiss()
                        }
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct EditCategoryView: View {
    @ObservedObject var studyManager: StudyManager
    @Bindable var category: StudyCategory
    @Binding var isPresented: Bool
    @State private var editedName: String = ""
    @State private var editedColor: String = "blue"
    
    let colors = [
        ("blue", Color.blue),
        ("green", Color.green),
        ("orange", Color.orange),
        ("purple", Color.purple),
        ("red", Color.red),
        ("pink", Color.pink),
        ("indigo", Color.indigo),
        ("teal", Color.teal)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("カテゴリ名") {
                    TextField("カテゴリ名を編集", text: $editedName)
                }
                
                Section("色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(colors, id: \.0) { colorName, color in
                            Button(action: {
                                editedColor = colorName
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(editedColor == colorName ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Section {
                    Button("削除", role: .destructive) {
                        studyManager.deleteCategory(category)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("カテゴリ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            category.name = editedName
                            category.color = editedColor
                            studyManager.saveCategoryEdit()
                            isPresented = false
                        }
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            editedName = category.name
            editedColor = category.color
        }
    }
}

#Preview {
    CategoryManagementView(studyManager: StudyManager(modelContext: ModelContext(try! ModelContainer(for: StudySession.self, StudyCategory.self))))
} 