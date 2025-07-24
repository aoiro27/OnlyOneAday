//
//  FamilyManagementView.swift
//  OnlyOneAday
//
//  Created by aoiro on 2025/07/21.
//

import SwiftUI

struct FamilyManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familyGoalManager = FamilyGoalManager()
    
    @State private var showingCreateFamily = false
    @State private var showingJoinFamily = false
    @State private var showingLeaveFamily = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 10) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("ファミリー管理")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("家族と一緒に目標を達成しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 現在のファミリー状況
                if familyGoalManager.isFamilyIdSet {
                    CurrentFamilyStatusView(familyGoalManager: familyGoalManager)
                }
                
                // アクションボタン
                VStack(spacing: 15) {
                    if !familyGoalManager.isFamilyIdSet {
                        // ファミリー未参加の場合
                        Button(action: {
                            showingCreateFamily = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("ファミリーを作る")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingJoinFamily = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                Text("ファミリーに参加する")
                                    .font(.headline)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    } else {
                        // ファミリー参加済みの場合
                        Button(action: {
                            showingLeaveFamily = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.minus")
                                    .font(.title2)
                                Text("ファミリーを抜ける")
                                    .font(.headline)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("ファミリー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateFamily) {
            CreateFamilyView(familyGoalManager: familyGoalManager)
        }
        .sheet(isPresented: $showingJoinFamily) {
            JoinFamilyView(familyGoalManager: familyGoalManager)
        }
        .alert("ファミリーを抜けますか？", isPresented: $showingLeaveFamily) {
            Button("キャンセル", role: .cancel) { }
            Button("抜ける", role: .destructive) {
                leaveFamily()
            }
        } message: {
            Text("ファミリーを抜けると、ファミリー目標にアクセスできなくなります。")
        }
        .onAppear {
            familyGoalManager.checkLocalFamilyId()
            if familyGoalManager.isFamilyIdSet {
                Task {
                    await familyGoalManager.fetchFamilyStatus()
                }
            }
        }
    }
    
    private func leaveFamily() {
        Task {
            let success = await familyGoalManager.leaveFamily()
            if success {
                print("Successfully left family")
            } else {
                print("Failed to leave family")
            }
        }
    }
}

// 現在のファミリー状況を表示するビュー
struct CurrentFamilyStatusView: View {
    @ObservedObject var familyGoalManager: FamilyGoalManager
    @State private var showingCopiedAlert = false
    @State private var showingMembers = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("ファミリーに参加中")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            if let status = familyGoalManager.familyStatus {
                HStack {
                    Text("ファミリーID: \(status.familyId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        UIPasteboard.general.string = status.familyId
                        showingCopiedAlert = true
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Text("表示名: \(status.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                showingMembers = true
                Task {
                    await familyGoalManager.fetchFamilyMembers()
                }
            }) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                    Text("メンバー一覧")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .alert("コピーしました", isPresented: $showingCopiedAlert) {
            Button("OK") { }
        } message: {
            Text("ファミリーIDをクリップボードにコピーしました")
        }
        .sheet(isPresented: $showingMembers) {
            FamilyMembersListView(familyGoalManager: familyGoalManager)
        }
    }
}

// ファミリー作成ビュー
struct CreateFamilyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var familyGoalManager: FamilyGoalManager
    
    @State private var userName = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("新しいファミリーを作成")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("ファミリーIDは自動生成されます")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("表示名")
                        .font(.headline)
                    
                    TextField("家族内での表示名", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await createFamily()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("ファミリーを作成")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .navigationTitle("ファミリー作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createFamily() async {
        let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isLoading = true
        
        // APIでファミリー作成を通知
        if let status = await familyGoalManager.createFamily(userName: trimmedUserName) {
            // ファミリー状況を更新
            familyGoalManager.familyStatus = status
            familyGoalManager.isFamilyIdSet = true
            
            // デバイストークンが取得できている場合は更新
            if SettingsManager.shared.hasDeviceToken() {
                await familyGoalManager.updateDeviceToken()
            }
        }
        
        isLoading = false
        dismiss()
    }
}

// ファミリー参加ビュー
struct JoinFamilyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var familyGoalManager: FamilyGoalManager
    
    @State private var userName = ""
    @State private var familyId = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("ファミリーに参加")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("既存のファミリーIDを入力してください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("表示名")
                            .font(.headline)
                        
                        TextField("家族内での表示名", text: $userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ファミリーID")
                            .font(.headline)
                        
                        TextField("ファミリーID", text: $familyId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await joinFamily()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("ファミリーに参加")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .disabled(!isFormValid || isLoading)
            }
            .navigationTitle("ファミリー参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !familyId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func joinFamily() async {
        let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFamilyId = familyId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isLoading = true
        
        // ファミリーIDの妥当性をチェック（8文字の英数字）
        let familyIdPattern = "^[A-Z0-9]{8}$"
        let familyIdRegex = try! NSRegularExpression(pattern: familyIdPattern)
        let range = NSRange(location: 0, length: trimmedFamilyId.utf16.count)
        
        if familyIdRegex.firstMatch(in: trimmedFamilyId, options: [], range: range) == nil {
            errorMessage = "ファミリーIDは8文字の英数字で入力してください"
            showingError = true
            isLoading = false
            return
        }
        
        // APIでファミリー参加を通知
        if let status = await familyGoalManager.joinFamily(userName: trimmedUserName, familyId: trimmedFamilyId) {
            // ファミリー状況を更新
            familyGoalManager.familyStatus = status
            familyGoalManager.isFamilyIdSet = true
            
            // デバイストークンが取得できている場合は更新
            if SettingsManager.shared.hasDeviceToken() {
                await familyGoalManager.updateDeviceToken()
            }
        } else {
            errorMessage = "ファミリーへの参加に失敗しました。ファミリーIDを確認してください。"
            showingError = true
            isLoading = false
            return
        }
        
        isLoading = false
        dismiss()
    }
}

// ファミリーメンバー一覧ビュー
struct FamilyMembersListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var familyGoalManager: FamilyGoalManager
    
    var body: some View {
        NavigationView {
            VStack {
                if familyGoalManager.familyMembers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("メンバーが見つかりません")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("ファミリーに参加しているメンバーが表示されます")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(familyGoalManager.familyMembers, id: \.memberId) { member in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.headline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("ファミリーメンバー")
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
    FamilyManagementView()
} 