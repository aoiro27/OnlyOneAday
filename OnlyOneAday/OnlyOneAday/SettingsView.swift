import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @EnvironmentObject var familyGoalManager: FamilyGoalManager
    @State private var showingTokenInput = false
    @State private var showingFamilyManagement = false
    @State private var tempToken = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("GitHub設定")) {
                    // アクセストークン設定
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Personal Access Token")
                                .font(.headline)
                            Text(settingsManager.hasGitHubToken() ? "設定済み" : "未設定")
                                .font(.caption)
                                .foregroundColor(settingsManager.hasGitHubToken() ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Button(settingsManager.hasGitHubToken() ? "変更" : "設定") {
                            tempToken = settingsManager.githubAccessToken
                            showingTokenInput = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                    
                    // デフォルトユーザー名設定
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("デフォルトユーザー名")
                                .font(.headline)
                            Text("検索時に自動入力されます")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        TextField("ユーザー名", text: $settingsManager.defaultGitHubUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.vertical, 4)
                    
                    // トークン削除ボタン
                    if settingsManager.hasGitHubToken() {
                        Button("トークンを削除") {
                            settingsManager.clearGitHubToken()
                            alertMessage = "トークンが削除されました"
                            showingAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("ファミリー設定")) {
                    // ファミリー状況表示
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ファミリー状況")
                                .font(.headline)
                            if familyGoalManager.isFamilyIdSet {
                                if let status = familyGoalManager.familyStatus {
                                    Text("ファミリーID: \(status.familyId)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("未設定")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        Button("管理") {
                            showingFamilyManagement = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("ヘルプ")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Personal Access Tokenの取得方法")
                            .font(.headline)
                        
                        Text("1. GitHub.comにログイン\n2. Settings > Developer settings > Personal access tokens\n3. Generate new token (classic)\n4. 必要な権限: public_repo, read:user")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingTokenInput) {
                TokenInputView(token: $tempToken, onSave: { newToken in
                    settingsManager.githubAccessToken = newToken
                    alertMessage = "トークンが保存されました"
                    showingAlert = true
                })
            }
            .sheet(isPresented: $showingFamilyManagement) {
                FamilyManagementView()
            }
            .alert("設定", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                familyGoalManager.checkLocalFamilyId()
                if familyGoalManager.isFamilyIdSet {
                    Task {
                        await familyGoalManager.fetchFamilyStatus()
                        // デバイストークンが取得できている場合は更新
                        if SettingsManager.shared.hasDeviceToken() {
                            await familyGoalManager.updateDeviceToken()
                        }
                    }
                }
            }
        }
    }
}

struct TokenInputView: View {
    @Binding var token: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("GitHub Personal Access Token")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("GitHub APIを使用するためにPersonal Access Tokenが必要です。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                SecureField("Personal Access Token", text: $token)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("保存") {
                    onSave(token)
                    dismiss()
                }
                .disabled(token.isEmpty)
                .frame(maxWidth: .infinity)
                .padding()
                .background(token.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("アクセストークン設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 