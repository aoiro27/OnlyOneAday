import SwiftUI
import SwiftData

struct PartnerSettingsView: View {
    @ObservedObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var partnerName = ""
    @State private var partnerCode = ""
    @State private var showingAddPartner = false
    @State private var showingConnectPartner = false
    @State private var showingDisconnectAlert = false
    
    var body: some View {
        NavigationView {
            List {
                if let partner = partnerManager.currentPartner {
                    // パートナー情報セクション
                    Section("パートナー情報") {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(partner.name)
                                    .font(.headline)
                                Text(partner.isConnected ? "接続中" : "未接続")
                                    .font(.caption)
                                    .foregroundColor(partner.isConnected ? .green : .orange)
                            }
                            Spacer()
                        }
                        
                        if partner.isConnected, let lastSync = partner.lastSyncDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                Text("最終同期: \(formatDate(lastSync))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 接続管理セクション
                    Section("接続管理") {
                        if partner.isConnected {
                            Button(action: {
                                showingDisconnectAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "link.badge.minus")
                                        .foregroundColor(.red)
                                    Text("接続を解除")
                                        .foregroundColor(.red)
                                }
                            }
                        } else {
                            Button(action: {
                                showingConnectPartner = true
                            }) {
                                HStack {
                                    Image(systemName: "link.badge.plus")
                                        .foregroundColor(.blue)
                                    Text("パートナーと接続")
                                }
                            }
                        }
                        
                        // パートナーコード表示
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("あなたのパートナーコード")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("コピー") {
                                    UIPasteboard.general.string = partnerManager.generatePartnerCode()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            Text(partnerManager.generatePartnerCode())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // 通知設定セクション
                    Section("通知設定") {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("パートナーの目標達成通知")
                                    .font(.subheadline)
                                Text("パートナーが目標を達成した時に通知を受け取ります")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ファミリー目標達成通知")
                                    .font(.subheadline)
                                Text("ファミリー目標を達成した時に通知を受け取ります")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    // パートナー未設定の場合
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("パートナーが設定されていません")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("パートナーと連携して、お互いの目標達成を通知し合いましょう")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                showingAddPartner = true
                            }) {
                                Text("パートナーを追加")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("パートナー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddPartner) {
                AddPartnerView(partnerManager: partnerManager)
            }
            .sheet(isPresented: $showingConnectPartner) {
                ConnectPartnerView(partnerManager: partnerManager)
            }
            .alert("接続を解除", isPresented: $showingDisconnectAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("解除", role: .destructive) {
                    partnerManager.currentPartner?.isConnected = false
                    try? partnerManager.modelContext.save()
                }
            } message: {
                Text("パートナーとの接続を解除しますか？")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct AddPartnerView: View {
    @ObservedObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var partnerName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("パートナー名") {
                    TextField("パートナーの名前を入力", text: $partnerName)
                }
                
                Section {
                    Text("パートナーを追加すると、お互いの目標達成を通知し合うことができます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("パートナー追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        if !partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            partnerManager.addPartner(name: partnerName.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                    }
                    .disabled(partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ConnectPartnerView: View {
    @ObservedObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    @State private var partnerCode = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("パートナーコード") {
                    TextField("パートナーコードを入力", text: $partnerCode)
                        .textInputAutocapitalization(.characters)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("パートナーコードの取得方法:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("1. パートナーのスマホでアプリを開く\n2. 設定 > パートナー設定\n3. 表示されるコードをコピー\n4. この画面でコードを入力")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if partnerManager.isConnecting {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("接続中...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let error = partnerManager.connectionError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("パートナーと接続")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("接続") {
                        Task {
                            await partnerManager.connectToPartner(partnerCode: partnerCode)
                            if partnerManager.connectionError == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(partnerCode.isEmpty || partnerManager.isConnecting)
                }
            }
        }
    }
}

#Preview {
    PartnerSettingsView(partnerManager: PartnerManager(modelContext: ModelContext(try! ModelContainer(for: Partner.self))))
} 